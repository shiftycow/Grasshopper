#!/usr/bin/perl
#
# grasshopper_control.pl
#
# This script provides a control interface to the polling and database daemons
#
#@ARGS:
#   start: starts the daemon(s) if they are not already running
#   stop [poller|db]: stops the daemon(s) if they are not already running
#   restart [poller|db]: stops and restarts the daemons
#   stats: queries the poller and host database for statistics
#   dashboard: starts the CLI dashboard
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

#system includes
use File::Spec;

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
use PrintToSocket;
use Logger;

my $action = lc $ARGV[0];

start() if($action eq "start");
stop() if($action eq "stop");
stop_db() if($action eq "stop_db");
restart() if($action eq "restart");
stats() if($action eq "stats");
dashboard() if($action eq "dashboard");

usage();

sub usage
{
    print "\ngrasshopper_control.pl - Grasshopper Network Monitoring System Controller\n";
    print "Usage: `./grasshopper_control.pl [start | stop | stop_db | restart | stats | dashboard]`\n";
    print "-------------------------------------\n";
    print "start: starts the poller and host database\n";
    print "stop: stops the poller and database\n";
    print "stop_db: stops the database if the poller is not running\n";
    print "restart: restarts the poller and database\n";
    print "stats: prints out some statistiscs from the poller and host_db\n"; 
    print "\n";

    exit;
}#end usage

sub start
{
    #
    #starts the polling and host database daemons
    #
    
    my $poller = "$APP_PATH/../bin/polling_daemon.pl";
    my $host_database = "$APP_PATH/../bin/host_db_daemon.pl";
    my $log_rotate = "$APP_PATH/../cli/log_rotate.pl";

    #see if the logs need to be rotated
    my $log_rotate_status = system $log_rotate;
    if($log_rotate_status != 0)
    {
        print "log rotation failed, exit code '$log_rotate_status'\n";
        exit;
    }
    print "Log Rotation [  OK  ]\n";

    my $host_database_status = system $host_database;

    #an exit code of -1 means that the database is already running, so ignore it.
    if($host_database_status == -1)
    {
        print "host database daemon already running, ignoring...\n";
    }

    else 
    {
        if($host_database_status != 0)
        {
            print "could not start host database, exit code '$host_database_status'\n";
            exit;
        }
    }

    print "Grasshopper Database [  OK  ]\n";
    
    my $poller_status = system $poller;
    if($poller_status == -1)
    {
        print "poller daemon already running, ignoring...\n";
    }
    else
    {
        if($poller_status != 0)
        {
            print "could not start polling daemon, exit code '$poller_status'\n";
            exit;
        }
    }
    print "Grasshopper Poller: [  OK  ]\n";
    
    exit;
}#end start

sub stop
{
    my $poller_socket = GrasshopperConfig::get_config_element("POLLER_PORT");
    my $db_socket = GrasshopperConfig::get_config_element("DB_SERVER_PORT");

    PrintToSocket::print_to_socket("#exit#",$poller_socket);
    print "#exit# message sent to poller on port $poller_socket\n";
    
    exit;
}#end stop

sub stop_db
{ 
    my $db_socket = GrasshopperConfig::get_config_element("DB_SERVER_PORT");
    PrintToSocket::print_to_socket("#exit#",$db_socket);
    print "#exit# message sent to host DB on port $db_socket\n";
    
    exit;
}#end stop_db

sub restart
{
    stop();
}

