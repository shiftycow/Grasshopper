#!/usr/bin/perl
#
# Pollers.pm
#
# This module provides various polling methods for getting specific
# data from equipment and saving it to disk or database
#
##############################################################################
#
# Copyright 2010-2011 - New Mexico State University Board of Regents
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# Contributing Authors:
#    Michael Harris (mharris@visgence.com)
#    Evan Salazar (sevan@nmsu.edu)
#
##############################################################################

use strict;
package Pollers;

#system includes
use SNMP;
use RRD::Simple;
use XML::Dumper;

#This script could be called from cron, so we need to find it's 
#path to make it portable
my $APP_PATH;
BEGIN
{
    $APP_PATH = File::Spec->rel2abs($0);
    (undef, $APP_PATH, undef) = File::Spec->splitpath($APP_PATH);
}

#local includes
use GrasshopperConfig;
use PrintToSocket;
use GrasshopperAPI;
use Logger;
use DriverMap;

#include the driver files and build the function reference hash
my $drivers = {};
my $default_driver;
BEGIN
{
    my $driver_path = "$APP_PATH/../lib/drivers";
    use lib "$APP_PATH/../lib/drivers/";
    $default_driver = GrasshopperConfig::get_config_element("DEFAULT_DRIVER");
    
    Logger::log("loading polling drivers ($driver_path)");
    my @driver_files = <$driver_path/*.pm>;
    foreach (@driver_files)
    {
        my $filename = $_;
        #print "filename: $filename\n";
        my $package;
        if($filename =~ /.+\/(.+)\.pm/)
        {
            $package = $1;
            
            #Logger::log("use $package; 1");
            eval "use $package; 1" or die $@;
            $drivers->{$package} = "loaded"; 
            Logger::log("driver '$package' ".$drivers->{$package});
        }
    }
    
    if($drivers->{$default_driver} eq undef)
    {
        print "Pollers.pm could not load default driver ($default_driver). Exiting\n";
        Logger::log("Pollers.pm could not load default driver ($default_driver). Exiting");
        exit(1);
    }
}#end driver loading

my $db_port = GrasshopperConfig::get_config_element("DB_SERVER_PORT");

sub poll_host
{
    #polls the specifed host
    my ($hostname,$group,$group_description) = @_; 
    
    my $poller_status = {};

    $poller_status->{"hostname"} = $hostname;
    $poller_status->{"task"} = "poll";
    
    #Get the host system table
    my $table_data = get_system_table($hostname,$group,$group_description);
    #Logger::log("poller determined system type: $system_type"); 
    
    if($table_data eq undef)
    {
        $poller_status->{"error"} = "could not get system table";
        return $poller_status;
    }
    
    my $driver = DriverMap::find_driver($table_data);
    
    # use the default driver if something went wrong and we couldn't find one
    $driver = $default_driver if($driver eq undef);
    
    #Logger::log("found driver: $driver");
    $poller_status->{'driver'} = $driver;
    
    #attempt to use the driver module for the specified system type
    if(!eval("\$poller_status->{'status'} = $driver"."::poll('$hostname','$group');"))
    {
        $poller_status->{"error"} = "polling driver '$driver' not found";
        Logger::log("could not use '$driver' for polling");
    }

    return $poller_status;
}#end poll host

sub write_rrds
{
    #uses a driver file to write the rrds for the specified host
    my ($hostname,$group,$driver) = @_; 
    
    # use the default driver if we don't get one
    #Logger::log("using driver: $driver for rrd writing");
    $driver = $default_driver if($driver eq undef);
    
    my $poller_status = "$hostname rrd ";

    #Logger::log("writing rrds using $driver driver");

    #Logger::log("\$poller_status .= $driver"."::poll($hostname,$group);");
    if(!eval("\$poller_status .= $driver"."::rrd('$hostname','$group');"))
    {
        $poller_status->{"error"} = "rrd driver '$driver' no found";
        Logger::log("could not use '$driver' for rrd writing");
    }

    return $poller_status;
}#end wrtite rrds

#get_mac_table is in version history if needed

sub get_system_table {
    #
    # gets system information from each host 
    #
    
    my ($hostname,$group,$group_description) = @_;

    my $community = GrasshopperConfig::get_config_element("SNMP_COMMUNITY");
    my $version = GrasshopperConfig::get_config_element("SNMP_VERSION");
    my $session = new SNMP::Session(DestHost => $hostname, Community => $community, Version => $version, UseSprintValue => 1);
    if($session eq undef)
    {
        Logger::log("session creation error: $SNMP::Session::ErrorStr");
        return undef;
    }

    #Logger::log("Fetching Data");
    #Get all the system info and store it to a hash
    my $tabledata = {};
    my  $vars = new SNMP::VarList(['system']);
    do {
        my ($val) = $session->getnext($vars);
        #if we have an error, the host is unreachable
        #
        if($session->{ErrorNum})
        {
            Logger::failed_host("$hostname (".$session->{ErrorNum}.")");
            return undef;
        }

        return $session->{ErrorNum} if($session->{ErrorNum});

        my $desc = $$vars[0]->tag; 
        if($$vars[0]->tag =~ /sys/) 
        {
            $tabledata->{$desc}->{'data'} = $val;
            $tabledata->{$desc}->{'description'} = $desc;
        }
    } while (!$session->{ErrorNum} and $$vars[0]->tag =~ /sys/);

    if ($tabledata eq {})
    {
        Logger::log("Pollers.pm unable to get system data for $hostname");
        return undef;
    }
    
    #update the host database with the information we gathered     
    my $host_data = {};
    $host_data->{"group"} = $group;
    $host_data->{"group_description"} = $group_description;
    $host_data->{"hostname"} = $hostname;
    $host_data->{"data_type"} = "sysData";
    $host_data->{"data"} = $tabledata;
    #Logger::log("updating host_db $host_data");
    GrasshopperAPI::update_host_db($host_data);

    #print Dumper($tabledata);
    #y $system_type =  $tabledata->{'sysDescr'}->{'data'};
    #$system_type =~ s/ /_/g;
    #$system_type =~ s/-//g;

    #Logger::log("systemType '$system_type'");
    return $tabledata;
}#end get system table

1;
