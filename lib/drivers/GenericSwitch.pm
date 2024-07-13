#!/usr/bin/perl
use strict;
#
# Grasshopper Polling driver for a generic switch
# 
# This driver file can be used as a template to create new ones
# for specific switches. 
#
# Each driver is composed of three functions: 
#    poll() 
#    rrd()
#    update_rrd()
#
# The external interface used by Pollers.pm is composed of
# poll() and rrd(). update_rrd() is for use in the driver only
#
#
# Drivers are included by Pollers.pm based on the sysDesc OID
# that is gathered when getting the system information. Spaces 
# in the sysDesc field are converted to underscores ('_') and 
# dashes (-) are removed because they can't be used in module names.
#
# Other drivers can `use` this one, too.
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


#when making a new driver, change this to match the filename
package GenericSwitch;

#system includes
use XML::Dumper;
use RRD::Simple;
use SNMP;
use File::Spec;

#This script could be called from cron, so we need to find it's 
#path to make it portable
my $APP_PATH;
BEGIN
{
    $APP_PATH = File::Spec->rel2abs($0);
    (undef, $APP_PATH, undef) = File::Spec->splitpath($APP_PATH);
}

#local includes
use lib "$APP_PATH/../"; #we're one directory below the other libraries
use GrasshopperConfig;
use Logger;
use DriverHelpers;


#
# Further user modification needed to create a new driver should be made below this line
#
sub poll
{
    # This is the main polling function
    # It gets counters from the specified tables and dumps 
    # them into an XML format that can be read by rrd() and converted
    # into an RRD file for display
    #

    #Logger::log("generic switch poll"); #return; #for testing

    my ($hostname, $group) = @_;

    my $host_swap_dir = GrasshopperConfig::get_config_element("HOST_SWAP_DIR");
    #path is absolute because it will probably be in /dev/shm

    my $community = GrasshopperConfig::get_config_element("SNMP_COMMUNITY");
    my $version = GrasshopperConfig::get_config_element("SNMP_VERSION");
    my $session = new SNMP::Session(DestHost => $hostname, Community => $community, Version => $version, UseSprintValue => 1);
 
    return "session creation error: $SNMP::Session::ErrorStr" unless (defined $session);

    ###################################################################
    #                     Fetch ifTable data                          #
    ###################################################################
    #Logger::log("Fetching Data");
    my $tabledata = $session->gettable('ifTable');
    Logger::log("Data Fetched for $hostname",1);
    #print Dumper($tabledata);
 
    my $xmlpath = "$host_swap_dir/$group/$hostname/";
 
    while (my ($key, $value) = each(%$tabledata))
    {
        my $xml = XML::Dumper::pl2xml($value);
        DriverHelpers::xml_dump($value,$xmlpath,$xml);
    }
 
    return "IFTABLE OK";
}#end poll

sub rrd
{
    # This function converts the temporary XML data produced by poll() 
    # into an RRD file
    #
    
    #Logger::log("generic switch rrd"); #return; #for testing
    
    my ($hostname,$group) =@_;

    Logger::log("converting $hostname xml dumps to rrd",1);
    my $host_rrd_dir = GrasshopperConfig::get_config_element("HOST_RRD_DIR");
    my $host_xml_dir = GrasshopperConfig::get_config_element("HOST_SWAP_DIR");

    $host_rrd_dir = "$APP_PATH/../$host_rrd_dir";
    #swap dir is absolute, since it will probably go on /dev/shm

    my $rrdpath = "$host_rrd_dir/$group/$hostname/";
    my $xmlpath = "$host_xml_dir/$group/$hostname/";

    # to hold some metadata about the interfaces
    my $graph_info = {};

    #get the directory listing
    my @xml_files = <$xmlpath/*.xml>;
    foreach (@xml_files)
    {
        my $filename = $_;
        my $ifdata = XML::Dumper::xml2pl($filename);

        my $octetsIn    = $ifdata->{'ifInOctets'};
        my $octetsOut   = $ifdata->{'ifOutOctets'};

        my $description = $ifdata->{'ifDescr'};
        #use a different field if ifDescr is blank

        my $port_number = "Port-".$ifdata->{'ifIndex'};

        $graph_info->{$port_number}->{'data'} = $port_number;
        $graph_info->{$port_number}->{'description'} = $description;
        $graph_info->{$port_number}->{'action'} = "load_port_info('$group','$hostname','index_".$ifdata->{'ifIndex'}.".rrd','$port_number','$description');";
        $graph_info->{$port_number}->{'sort_key'} = $ifdata->{'ifIndex'}; #a key to sort the indexes by

        #Logger::log("octetsIn: $octetsIn    octetsOut: $octetsOut");
        update_rrd($ifdata,$rrdpath);
    }#end foreach XML file

    #update the host database with the information we gathered 
    my $host_data = {};
    $host_data->{"group"} = $group;
    $host_data->{"hostname"} = $hostname;
    $host_data->{"data_type"} = "graphData";
    $host_data->{"data"} = $graph_info;
    #Logger::log("updating host_db $host_data");

    # but only update the host db if we were able to write some RRDs
    # $graph_info will still be an empty hashref if we didn't enter the loop above
    GrasshopperAPI::update_host_db($host_data) if(scalar(keys(%$graph_info)));

    #my $graph_info_xml = XML::Dumper::pl2xml($graph_info); 
    
    return "$hostname rrd: OK";    
}#end rrd

sub update_rrd
{
    # This method writed the supplied data into the specified RRD file
    # One host can have many RRD files, so this function is broken out for use by 
    # rrd() above
    #

    my ($ifdata,$rrdpath) =@_;

    my  $rrdfile = $rrdpath ."index_". $ifdata->{'ifIndex'} . ".rrd";

    my $rrd = RRD::Simple->new( file => $rrdfile );

    unless(-e $rrdfile) {
        Logger::log("Creating File $rrdfile");
        `mkdir -p $rrdpath`;
        $rrd->create(
                bytesInPerSec => "Counter",
                bytesOutPerSec => "Counter",
                ucastInPerSec => "Counter",
                ucastOutPerSec => "Counter",
                nonUcastInPerSec => "Counter",
                nonUcastOutPerSec => "Counter",
                errorsInPerSec => "Counter",
                errorsOutPerSec => "Counter"
                );
    }

    my $octetsIn    = $ifdata->{'ifInOctets'};
    my $octetsOut   = $ifdata->{'ifOutOctets'};
    my $ucastIn     = $ifdata->{'ifInUcastPkts'};
    my $ucastOut    = $ifdata->{'ifOutUcastPkts'};
    my $nonUcastIn  = $ifdata->{'ifInNUcastPkts'};
    my $nonUcastOut = $ifdata->{'ifOutNUcastPkts'};
    my $errorsIn    = $ifdata->{'ifInErrors'};
    my $errorsOut   = $ifdata->{'ifOutErrors'};

    #Logger::log("$rrdfile In: $in Out: $out");

    $rrd->update("$rrdfile",time(),
            bytesInPerSec     => $octetsIn,
            bytesOutPerSec    => $octetsOut,
            ucastInPerSec     => $ucastIn,
            ucastOutPerSec    => $ucastOut,
            nonUcastInPerSec  => $nonUcastIn,
            nonUcastOutPerSec => $nonUcastOut,
            errorsInPerSec    => $errorsIn,
            errorsOutPerSec   => $errorsOut
    );
}#end update_rrd
 
1;
