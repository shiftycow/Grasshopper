#!/usr/bin/perl
#
#Logger.pm
#
#This file provides functions to log errors and such to a file
#It also supports logging to syslog through the "logger" command
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

package Logger;

use strict;

#Local includes
use GrasshopperConfig;

# This script could be called from cron, so we need to find it's 
# path to make it portable
my $APP_PATH;

BEGIN
{
    $APP_PATH = File::Spec->rel2abs($0);
    (undef, $APP_PATH, undef) = File::Spec->splitpath($APP_PATH);
}


#############################################################
#
#Log an error, this will be stored to the log file with the 
#username and date as well as printed to std error
#@ARGS
#$msg - This is messge being logged, please dont put any /n in the message
##############################################################
sub log {

    my ($msg,$level) = @_;
    $msg =~ s/\n/<BR>/g;

    my $debug_level = GrasshopperConfig::get_config_element('debug_element');
    return if($level > $debug_level);

    #`logger "[GRASSHOPPER] $msg"`;

    my $log_file = GrasshopperConfig::get_config_element('logfile');
    $log_file = "$APP_PATH/../$log_file";
    my $date = `date`;
    chomp $date;
    open(LOG,">>$log_file");
    
    print LOG "$date: $msg\n";
    close(LOG);
}#emd log

sub bench
{
    #writes data to a benchmark file

    my ($msg) = @_;
    $msg =~ s/\n/<BR>/g;

    my $bench_file = GrasshopperConfig::get_config_element("benchmark_file"); 
    open(LOG,">>$bench_file");

    print LOG "$msg\n";
    close(LOG);
}

sub failed_host
{
    #writes the log of failed hosts
    my ($msg) = @_;
    
    my $log_file = GrasshopperConfig::get_config_element('FAILED_HOST_LOG');
    $log_file = "$APP_PATH/../$log_file";
    my $date = `date`;
    chomp $date;
    open(LOG,">>$log_file");
    
    print LOG "$date: $msg\n";
    close(LOG);
}#end failed_host

sub rotate
{
    #rotates the various grasshopper log files
    #
    # the rotation can also be forced, thus ignoring the size constraints in the config
    #

    my ($force) = @_;
    
    my $log_size = 0;
    $log_size = GrasshopperConfig::get_config_element('LOG_SIZE') if($force eq undef);
     
    `logger [GRASSHOPPER] max log size is 0, rotation forced` if($log_size == 0);

    #log size is specified in KB in the conf, so multiply it
    $log_size = $log_size * 1024;

    my $old_logs = GrasshopperConfig::get_config_element('OLD_LOGS');
    #print "Log size: $log_size\n"; #DEBUG
    #print "old logs: $old_logs\n"; #DEBUG

    my $logs = {};
    $logs->{'log'} = GrasshopperConfig::get_config_element('logfile');
    $logs->{'failed_hosts'} = GrasshopperConfig::get_config_element('FAILED_HOST_LOG');
    $logs->{'benchmarks'} = GrasshopperConfig::get_config_element("benchmark_file"); 
    
    while(my ($log, $file) = each(%$logs))
    {
        #rotate each log set...
        $file = "$APP_PATH/../$file";

        my $size = -s $file;
        #print "file $file is $size bytes\n"; #DEBUG

        if($size >= $log_size) #...if the current file is big enough
        {
            #report that we are doing the rotation through syslog
            `logger [GRASSHOPPER] rotating $log log '$file', size: $size`;
            #print "[GRASSHOPPER] rotating $log log '$file', size: $size\n"; #DEBUG

            #we convert the $old_logs string into an int, just in case it is malformed in some way
            for(my $i = int($old_logs); $i > 1; $i--)
            {
                #print "$file.".($i-1) ."\n";
                if(-e "$file.".($i-1) ) #check that the file exists so we don't get cluttered with errors
                {
                    my $mv_string = "mv $file.".($i-1)." $file.$i";
                    #print "$mv_string\n"; #DEBUG
                    `$mv_string`;
                }
            }

            #rename the current file
            `mv $file $file.1`;

            #tocuh a new one
            `touch $file`;
        }#end log_size exceeded

    }#end foreach logs
}#end rotate

1;
