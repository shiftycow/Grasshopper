#!/usr/bin/perl
#
# The Grasshopper Polling daemon
# 
# The daemon starts several worker processes with which it communicates using
# TCP sockets. Each worker thread requests work from the server, which
# schedules them to poll or write the temporary polling data to RRDs
#
# The server also keeps track of benchmarking data used for debugging 
# and tuning purposes.
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
use IO::Socket;
use English; #needed to get $PID
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
use Pollers;
use GrasshopperConfig;
use Logger;
use PrintToSocket;
use GrasshopperAPI;

#should we not start a daemon?
my $nodaemon = $ARGV[0];


#spawn a new process
my $pid = 0;
$pid = fork() if($nodaemon eq undef);
if($pid != 0)
{
    #we are the parent
    exit(); #exit to dissasociate ourselves from a terminal
}

#set up signal handlers
$SIG{ALRM} = \&end_unexpected; #a timer will end the program if it has not received updates from workers

$pid = $PID;

my $control_port = GrasshopperConfig::get_config_element("POLLER_PORT");
my $db_port = GrasshopperConfig::get_config_element("DB_SERVER_PORT");

my $host_xml_dir = GrasshopperConfig::get_config_element("HOST_SWAP_DIR");

#maximum number of workers to schedule for writting RRD files at once
my $max_rrd_writers = GrasshopperConfig::get_config_element("MAX_RRD_WRITERS");
my $rrd_writers = 0;

#maximum number of worker threads to spawn
my $max_workers = GrasshopperConfig::get_config_element("MAX_WORKERS");
my %workers; #list of worker PIDs to wait on 

#Get the timeout to wait on a bad thread
my $timeout = GrasshopperConfig::get_config_element("TIMEOUT");


#sanity check config
if($max_workers <= $max_rrd_writers)
{
    print "MAX_WORKERS must be greater than MAX_RRD_WRITERS\n";
    exit(1);
}

#open a socket to listen for control messages
#print "daemon opening socket \n";
my $sock = new IO::Socket::INET (
                                LocalHost => 'localhost',
                                LocalPort => $control_port,
                                Proto => 'tcp',
                                Listen => 9999,
                                Reuse => 1,
                                );
my $now = time;
die("Cannot bind to socket. Is another polling daemon running? $now") if($sock eq undef);
print "Grasshopper Poller Daemon Started('$PID')\n";
Logger::log("Grasshopper Poller Daemon Started('$PID')");
Logger::log("Control port: $control_port");

#clear out old host data before starting polling
`rm -r $host_xml_dir` if($host_xml_dir ne undef);
`mkdir $host_xml_dir` if($host_xml_dir ne undef);

my $exit = 0; #a flag that the program needs to exit and the workers should finish up

my $poll_queue = get_hosts(); #hosts waiting to be polled
my $rrd_queue = (); #hosts ready to be written to RRD

my $last_polled = {}; #the last time hosts were polled. using this hash eliminated
                      #the need for a data structure to describe hosts

my $hosts_completed = 0; #benchmark counter for hosts completed
my $start_time; #variable to hold the start time on polling 
my $last_count = 0; #helper for logging the status of hosts

PrintToSocket::print_to_socket("#spawn#",$control_port); #bootstrap "spawn" command
my $status_report;
my $listener;

while($listener = $sock->accept())
{
    while(defined($status_report = <$listener>))
    {
        #print "packet length: ".length $status_report."\n";
        chomp $status_report;
        #print "status report: '$status_report'\n";
       
        $last_count = $hosts_completed;
        #if we get an exit command, exit cleanly
        if($status_report =~ /#exit#/)
        {
            Logger::log("exit command recieved by daemon");
            $exit = 1;
        }#end exit

        #if it is a notice about a worker exiting, delete it from the list
        if($status_report =~ /#worker '([0-9]+)' done#/)
        {
            #reset the timeout alarm
            alarm($timeout);

            my $exiting_pid = $1;
            Logger::log("worker $exiting_pid done",1);
            delete($workers{$exiting_pid});
        }#end worker done

        #if we get a spawn command, spawn a new worker
        if($status_report =~ /#spawn#/)
        {
            $start_time = time();
            Logger::log("grasshopper_daemon spawning workers",1);
            for(my $i = 0; $i < $max_workers; $i++)
            {
                if(scalar(keys %workers) >= $max_workers)
                {
                    $i = $max_workers;
                }

                else
                {
                    spawn_child();
                }
            }
        }#end spawn

        #if we get a request for a hostname
        if($status_report =~ /#worker '([0-9]+)' waiting for hostname#/)
        {
            my $worker_pid = $1; 
            my $task_descriptor = {};
            $task_descriptor->{"pid"} = $worker_pid;

            #reset the timeout alarm
            alarm($timeout);
            
            #TODO: make the polling queue have the same data structure as the rrd one
            #(i.e. including driver information)

            my $host = undef; #a "host" data structure of the kind that lives on the RRD queue
            my $task = "poll"; #default task is polling

            #this is a simple scheduler that chooses between polling and rrd writing
            #we only want a few threads writing RRDs at once, but as many as possible
            #can be polling
            $host = pop @$rrd_queue if($rrd_writers < $max_rrd_writers);
            if($host ne undef)
            {
                $task = "rrd";
                $rrd_writers++; #we're going to have a thread writing rrds
            }

            else
            {
                $host = pop @$poll_queue;
                $task = "poll";
            }
            

            if($host ne undef and $exit == 0)
            {
                $task_descriptor->{"task"} = $task;
                $task_descriptor->{"host"} = $host;
            }

            else
            {
                $task_descriptor->{"task"} = "exit";
            }
            
            GrasshopperAPI::send_task($task_descriptor,$listener);
        }#end hostname return
       
        #if we get a status report that a host is ready to be written to RRD,
        #add it to the rrd queue
        #
        if($status_report =~ /#'([a-z0-9\-_]+)' XML ready#/)
        {
            my $hostname = $1;
            #reset the timeout alarm
            alarm($timeout);
           
            my $task_descriptor = Storable::fd_retrieve($listener);
            my $host = $task_descriptor->{"host"};
            
            my $hostname = $host->{"hostname"};
            Logger::log("$hostname ready to be written to rrd",1);
                        
            #push the host onto the rrd queue
            push @$rrd_queue,$host;
            
            #note the poll time
            $last_polled->{$hostname} = time;
        }#end rrd written
        
        #if we get a report that a host's RRD is done, add it back to the poll queue
        if($status_report =~ /#'([a-z0-9\-_]+)' RRD ready#/)
        {
            #reset the timeout alarm
            alarm($timeout);

            my $hostname = $1;
            Logger::log("$hostname RRD written",1);
            #print("$hostname RRD written");
            $rrd_writers--; #a thread is done writting rrds    

            #and we've completed a host
            $hosts_completed++;
            
            #push the host onto the poll queue
            #push @$poll_queue,$hostname;
        }#end rrd ready

        #if there are no more threads and the exit flag is set, exit the program
        if(scalar(keys %workers) == 0)
        {
            close($sock);
            if($exit == 1)
            {
                #if the exit flag was set, shut down the host database as well
                Logger::log("sending exit command to host database");
                PrintToSocket::print_to_socket("#exit#",$db_port);
            }
            end_cleanly();
        }
         
        #TODO: make this a config variable
        #make a mark in the log every <n> hosts
        if($hosts_completed % 100 == 0 and $hosts_completed > $last_count)
        {   
            my $now = time;
            my $runtime = $now - $start_time;
            Logger::log("Completed $hosts_completed hosts in $runtime seconds",0);
        }
    }#end status report processing
}#end if(accept)

Logger::log("polling daemon unable to accept() on socket");
close($sock);
end_cleanly();

########################
sub end_cleanly
{
    #my (@workers) = @_;
    #wait for all the children to exit
    #this way we don't get zombies
    
    foreach (keys %workers)
    {
        my $pid = $_;
        Logger::log("daemon waiting for process: $pid");
        waitpid($pid,0);
    }
    my $end_time = time();
    my $runtime = ($end_time - $start_time) / 60.0;
    Logger::bench("$end_time,$hosts_completed,$runtime,$max_workers,$max_rrd_writers");
    
    PrintToSocket::print_to_socket("#filedump#",$db_port);
    Logger::log("all work done, daemon exiting. completed $hosts_completed hosts in $runtime minutes");
     
    exit();
}#end end_cleanly

sub end_unexpected {
    foreach (keys %workers)
    {
        my $pid = $_;
        
        if(kill 0, => $pid) #if we can send a signal to the process, kill it
        {
            kill 9 => $pid;
            Logger::log("daemon waiting for process: $pid");
            waitpid($pid,0);
        }
    }#end worker killing

    my $end_time = time();
    my $runtime = ($end_time - $start_time) / 60.0;
    Logger::log("Unexpected Close, runtime $runtime");
    print "Unexpected Close, runtime $runtime\n";
    close($sock);
    exit();
}


sub worker_thread
{
    # worker threads ask for work to be assigned from the server
    # and then do their assigned tasks
    # putting this bit in a method is easier to read, but shouldn't
    # be confused with user-level (pthread) threads. These are still
    # independent processes that have been fork()'d
    # 

    my $pid = $PID;
    #print "worker thread started\n";
    while(1)
    { 
        #print "requesting hostname\n";
        my $task_descriptor = GrasshopperAPI::get_task($pid);

        my $task = $task_descriptor->{"task"};
        
        if($task eq "exit")
        {
            GrasshopperAPI::finish_task($task_descriptor);
            return;
        }
        
        my $status; #for holding the status of tasks 
        if($task eq "poll")
        {
            #check when the last time the host was polled was an sleep if it was too recently
            my $poll_time = time - $last_polled;
            my $sleep_time = 0;
            $sleep_time = 300 - $poll_time if($poll_time < 300 and $poll_time > 1);
            Logger::log("host was polled too recently, sleeping for '$sleep_time' seconds\n",2) if($poll_time < 300 and $sleep_time > 0);
            sleep($sleep_time);
           
            my $host = $task_descriptor->{"host"};
            my $hostname = $host->{"hostname"};
            my $group = $host->{"group"};
            my $group_description = $host->{"group_description"};

            $status = Pollers::poll_host($hostname,$group,$group_description);
            
            #let the dispatcher know what kind of system we found and if there were errors
            $task_descriptor->{"error"} = $status->{"error"};
            $task_descriptor->{"driver"} = $status->{"driver"};
            #print "worker thread sending driver '". $status->{"driver"}."' to dispatcher\n";

            GrasshopperAPI::finish_task($task_descriptor);
        }#end polling task

        if($task eq "rrd")
        {
            my $host = $task_descriptor->{"host"};
            
            my $hostname = $host->{"hostname"};
            my $group = $host->{"group"};
            my $driver = $host->{"driver"};
            
            #Logger::log("group: '$group'");
            $status = Pollers::write_rrds($hostname,$group,$driver);
            GrasshopperAPI::finish_task($task_descriptor);
        }#end rrd task
               
    }#end worker loop
}#end worker thread

sub spawn_child
{
    #spawns a new child and adds the PID to the workers list
    #

    my ($argument) = @_;
    Logger::log("attempting to spawn worker",3);
    if(scalar(keys %workers) >= $max_workers)
    {
        Logger::log("MAX WORKERS SPAWNED");
        return;
    }

    my $pid = fork();
    
    if($pid == 0)
    {
        #perform the task
        worker_thread();
        exit();
    }#end child section

    $workers{$pid} = "1";
    return;
}#end spawn child

#
########## Helper Functions #######################
#

sub get_hosts
{
    #gets a list of hosts to poll
    #the host list comes as a csv, so this function splits out the values and builds 
    #the data structures required for the hosts
    #

    open HOST_LIST,"<$APP_PATH/../conf/hosts.lst";
    my @hosts = <HOST_LIST>;
    close HOST_LIST;
   
    my $host_queue = ();
    foreach (@hosts)
    {
        #the hostname config comes as a CSV, so split out the values
        chomp $_;
        
        my ($hostname,$group_description,$group) = split(/,/,$_);
        
        #Logger::log("reading config: '$hostname','$group_description','$group'");
        
        my $host = {};
        $host->{"hostname"} = $hostname;
        $host->{"group_description"} = $group_description;
        $host->{"group"} = $group;

        push @$host_queue,$host;
    }

    return $host_queue;
}#end get_hosts


