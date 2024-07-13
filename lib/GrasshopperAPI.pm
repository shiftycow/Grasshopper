#!/usr/bin/perl
#
# GrasshopperAPI.pm
#
# This module provides an API for the poller and 
# host database. It is meant to be used instead of raw sockets,
# so that it is easier to change the IPC model in the future
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

package GrasshopperAPI;

#
# system includes
#
use XML::Dumper;
use Storable; #for IPC of datastructures

# This script could be called from cron, so we need to find it's 
# path to make it portable
my $APP_PATH;

BEGIN
{
    $APP_PATH = File::Spec->rel2abs($0);
    (undef, $APP_PATH, undef) = File::Spec->splitpath($APP_PATH);
}

use lib "$APP_PATH/../lib";

#local includes
use GrasshopperConfig;
use Logger;
use PrintToSocket;
use HostTree;

my $poller_port = GrasshopperConfig::get_config_element("POLLER_PORT");
my $db_port = GrasshopperConfig::get_config_element("DB_SERVER_PORT");

###################### Service Control Functions ####################
sub stop_poller
{
    #sends an exit command to the polling daemon and watches the process
    #listing to make sure it has stopped
}#end stop poller

sub stop_database
{
    #sends an exit command to the database and watches the process
    #to make sure it has stopped

}#end stop poller



#####################     IPC Functions    ##########################
#TODO: have a generic "send data" method instead of send_task, send_host_db_nodes, etc...
sub send_task
{
    #serializes a task descriptor and sends it to a waiting process
    my ($task_descriptor,$sock) = @_;
   
    Storable::nstore_fd($task_descriptor, $sock);
    return;
}#end send_task

sub get_task
{
    # called by worker threads - retrieves a task to perform
    # and related arguments from the management thread
    my ($pid) = @_;

    my $task_descriptor = {};

    #TODO: make the task request a data structure as well?
    my $sock = PrintToSocket::print_to_socket("#worker '$pid' waiting for hostname#\n",$poller_port,"open","noexit");
    if($sock eq undef)
    {
        Logger::log("could not get task from master");
        exit(1);
    }
    
    my $task_descriptor = Storable::fd_retrieve($sock);
    close($sock);
    
    return $task_descriptor;
}#end get_task

sub finish_task
{
    # called by worker threads to let the controller know that they
    # have finished their task
    
    my ($task_descriptor) = @_;

    my $task = $task_descriptor->{"task"};

    #different tasks could have different information in the task descriptor
    #so we pull out the data in the conditionals for clarity
    #
    my $status;
    Logger::log("finishing task $task",2);
    if($task eq "rrd")
    {
        my $hostname = $task_descriptor->{"host"}->{"hostname"};
        $status = PrintToSocket::print_to_socket("#'$hostname' RRD ready#\n",$poller_port,undef,"noexit");
    }

    if($task eq "poll")
    {
        my $hostname = $task_descriptor->{"host"}->{"hostname"};
        my $sock = PrintToSocket::print_to_socket("#'$hostname' XML ready#\n",$poller_port,"open","noexit");
        Storable::nstore_fd($task_descriptor,$sock);
        close $sock;
        $status = "finished polling task";
    }

    if($task eq "exit")
    {
        my $pid = $task_descriptor->{"pid"};
        $status = PrintToSocket::print_to_socket("#worker '$pid' done#\n",$poller_port, undef, "noexit");
    }

    if($status eq undef)
    {
        Logger::log("could not inform master that task $task is finished");
        exit(1);
    }
}#end finish task


#################### Database interaction functions #################
sub send_host_db_nodes
{
    my ($nodes, $sock) = @_;
  
    if($nodes eq undef)
    {
        Logger::log("GrasshopperAPI tried to send nodes, but did not get data! using empty hash",1);
        $nodes = {};
    }

    Storable::nstore_fd($nodes, $sock);
    #the client will close the socket
    return 1;
}#end send_host_db_nodes

sub get_host_db_nodes
{
    #retrieves a list of host database nodes under the specified path. 
    #Results are serialized as XML
    #
    my ($path) = @_;
    
    my $sock = PrintToSocket::print_to_socket("#get_nodes '$path'#\n",$db_port,"open","noexit");
    
    if($sock eq undef)
    {
        #if we couldn't open a socket, go directly for the database
        Logger::log("GrasshopperAPI could not open connection to host database, falling back to dump file");
        my $database = read_host_db();
        my $nodes = HostTree::get_nodes($database,$path);
        my $xml = XML::Dumper::pl2xml($nodes);
        return $xml;
    }
    Logger::log("GrasshopperAPI loading nodes from socket",1);
    my $nodes = Storable::fd_retrieve($sock); 

    my $xml = XML::Dumper::pl2xml($nodes);
    close($sock);
    
    return $xml;
}#end host_db_nodes

sub update_host_db
{
    #sends an update request to the host db daemon
    my ($host_data) = @_;
    
    if($host_data eq undef)
    {
        
        Logger::log("GrasshopperAPI tried to update Host DB but got no data!");
        return undef;
    }

    my $sock = PrintToSocket::print_to_socket("#update#\n",$db_port,"open","noexit");
    if($sock eq undef)
    {
        Logger::log("GrasshopperAPI cannot send update request to DB");
        return undef;
    }

    Storable::nstore_fd($host_data,$sock);
    close($sock);

    return 1;
}#end update_hostdb


sub read_host_db
{
    Logger::log("Reading HostDB XML from file",1);
    my $dbfile = GrasshopperConfig::get_config_element("HOST_DATABASE_XML");
    $dbfile = "$APP_PATH/../$dbfile";

    my $perl = XML::Dumper::xml2pl($dbfile) if(-e $dbfile);
    
    if($perl eq undef)
    {
        Logger::log("Could not read HostDB XML file!");
    }
    
    return $perl;
}#end read_host_db;

sub write_host_db
{

}#end write_host_db

1;
