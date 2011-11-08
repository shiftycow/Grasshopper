#!/usr/bin/perl
#
# host_db_daemon.pl
#
# This script runs a daemon to handle queries of the host database
#
# The host database is huge (having information on every port on every switch)
# so this daemon keeps in in memory for quick access by clients
#
# if an argument is supplied, the server will not daemonize
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
#    Michael Harris (mharris@nmsu.edu)
#    Evan Salazar (sevan@nmsu.edu)
#
##############################################################################

use strict;

#system includes
use XML::Dumper;
use IO::Socket;
use File::Spec;
use Storable;

#This script could be called from cron, so we need to find it's 
#path to make it portable
my $APP_PATH;

BEGIN
{
        $APP_PATH = File::Spec->rel2abs($0);
            (undef, $APP_PATH, undef) = File::Spec->splitpath($APP_PATH);
}

use lib "$APP_PATH/../lib";

#local includes
use GrasshopperConfig;
use GrasshopperAPI;
use PrintToSocket;
use Logger;
use HostTree;

#should we start a daemon?
my $nodaemon = $ARGV[0];

#daemonize if requested
my $pid = 0;
$pid = fork() if($nodaemon eq undef);
exit() if($pid != 0);


my $CONTROL_PORT = GrasshopperConfig::get_config_element("DB_SERVER_PORT");

my $sock = new IO::Socket::INET (
                                LocalHost => 'localhost',
                                LocalPort => $CONTROL_PORT,
                                Proto => 'tcp',
                                Listen => 9999,
                                Reuse => 1,
				);

if($sock eq undef)
{
    print "Cannot bind to socket on port $CONTROL_PORT. is another server already running?\n";
    exit(-1);
}

#load the previous host database into memory
my $host_database = GrasshopperAPI::read_host_db();
#my $host_database = {};

my ($listener,$status_report);

#TODO: could this time out after long periods of inactivity? - probably not, according to PerlMonks
while($listener = $sock->accept())
{
    while(defined($status_report = <$listener>))
    {
        chomp $status_report;

        if($status_report =~ /#exit#/)
        {
            Logger::log("exit command recieved by host database daemon");
            close($sock);
            dump_xml();
            exit;
        }#end exit

        #returns a set of nodes to be sent to the UI
        if($status_report =~ /#get_nodes '([A-z0-9\.\-_]+)'#/)
        {
            Logger::log("host database received node request",1);
            my $path = $1;
            my $nodes = HostTree::get_nodes($host_database,$path);    
            GrasshopperAPI::send_host_db_nodes($nodes,$listener);
        }#end get_nodes

        #updates the host database with information on the specified host
        if($status_report =~ /#update#/)
        {
            my $host_data = Storable::fd_retrieve($listener);
            my $group = $host_data->{"group"};
            my $hostname = $host_data->{"hostname"};
            my $data_type = $host_data->{"data_type"};
            my $data = $host_data->{"data"};
            my $group_description = $host_data->{"group_description"};

            Logger::log("host db received update request: $group $hostname $data_type",1);

            #update the host data
            $host_database->{'root'}->{'child'}->{$group}->{'child'}->{$hostname}->{'child'}->{$data_type}->{'child'} = $data;
            
            #update the group description if neccessary
            $host_database->{'root'}->{'child'}->{$group}->{'description'} = $group_description if($group_description ne undef);
        }#end update hostdb

        #dumps the host database to a file
        #used for debugging
        if($status_report =~ /#filedump#/)
        {   
            #print "dumping database\n";
            Logger::log("Filedump command received, dumping database");
            dump_xml();
        }   

    }#end status report = $listener
}#end $sock->accept

Logger::log("host_db_daemon accept failed or timed out!");
dump_xml();

sub dump_xml {
    #dump the host database into a file
    Logger::log("Dumping database to file");
    my $dbfile = GrasshopperConfig::get_config_element("HOST_DATABASE_XML");
    
    #append the $APP_PATH to get the location of the DB file
    $dbfile = "$APP_PATH/../$dbfile";
    
    my $xml = XML::Dumper::pl2xml($host_database);
    open(FILE,">$dbfile");
    print FILE $xml;
    close FILE;
}#end dump_xml

