#!/usr/bin/perl
#
# port_data.cgi
#
# This script sends statistical information for for a network interface
# based on it's rrd. It also sends the info needed to build a graph
#
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

use lib "../lib";

#system includes
use CGI;
use XML::Dumper;
use POSIX; #for date formatting

#local includes
use Logger;
use ReadRRD;

my $co = new CGI;

my $group = $co->param('group');
my $hostname = $co->param('hostname');
my $rrd = $co->param('rrd');
my $port_name = $co->param('port_name');
my $description = $co->param('description');


my $RRD_DIR = "../data/grasshopper_data";
my $rrdfile = "$RRD_DIR/$group/$hostname/$rrd";


my $port_data = {};
$port_data->{'title'} = "$port_name";
$port_data->{'description'} = $description;
$port_data->{'rrd'} = $rrd;
$port_data->{'group'} = $group;
$port_data->{'hostname'} = $hostname;

my $last_updated = POSIX::strftime("%H:%M:%S %m-%d-%Y",localtime ReadRRD::last_updated($rrdfile) );
$port_data->{'last_updated'} = $last_updated;

my $dsinfo = ReadRRD::get_dslist($rrdfile);
my $ds;
foreach $ds (@{$dsinfo}) {

    if($ds =~ /^([A-z0-1_-]+)(In|Out)([A-z0-1_-]*)$/) {
    
	$port_data->{'graph'}->{$1}->{'dslist'}->{$2} = $ds;	
	$port_data->{'graph'}->{$1}->{'stats'}->{$2} = ReadRRD::get_stats($rrdfile,$ds,getScale($ds),1);
	$port_data->{'graph'}->{$1}->{'colors'}->{$2} = getColor($ds);
	$port_data->{'graph'}->{$1}->{'lines'}->{$2} =  getLine($ds);
	$port_data->{'graph'}->{$1}->{'labels'}->{$2} =  getLabel($ds);
	$port_data->{'graph'}->{$1}->{'yaxis'} =  getYAxis($ds);
	$port_data->{'graph'}->{$1}->{'scale'} =  getScale($ds);
    }
    
    else {
	$port_data->{'graph'}{$ds}->{'dslist'}->{'Single'} = $ds;		
	$port_data->{'graph'}{$ds}->{'stats'}->{'Single'} = ReadRRD::get_stats($rrdfile,$ds,getScale($ds),1);
    }
}#end foreach $ds


print $co->header('text/xml');
my $xml = XML::Dumper::pl2xml($port_data);
#Logger::log("port data xml: $xml");
print $xml;


sub getColor()
{
    #maps graph colors to their corresponding ds values
    
    my ($ds) = @_;
    
    return "00cf00" if($ds =~ /bytesIn/);
    return "002a97" if($ds =~ /bytesOut/);
    return "fff200" if($ds =~ /castIn/);
    return "00234b" if($ds =~ /castOut/);
    return "f51d30" if($ds =~ /errorsIn/);
    return "00cf00" if($ds =~ /errorsOut/);
}#end getColor

sub getLabel() 
{
    #maps axis labels to their corresponding ds values
    my ($ds) = @_;
    
    return "Average Bits In" if($ds =~ /bytesIn/);
    return "Average Bits Out" if($ds =~ /bytesOut/);
    return "Average Packets In" if($ds =~ /castIn/);
    return "Average Packets Out" if($ds =~ /castOut/);
    return "Average Errors In" if($ds =~ /errorsIn/);
    return "Average Errors Out" if($ds =~ /errorsOut/);
}#end getLabel

sub getLine()
{
    my ($ds) = @_;
    
    return "";
}#end getLine

sub getYAxis()
{
    #
    #maps y-axis unit decriptions to corresponding ds values
    #
    my ($ds) = @_;
    

    return "Bits Per Second" if($ds =~ /bytes/);
    return "Packets Per Second" if($ds =~ /cast/);
    return "Errors Per Second" if($ds =~ /errors/);
}#end getyAxis


sub getScale() 
{
    #
    # sets the scale depending on units
    #
    my ($ds) = @_;
    
    #if the unit is bytes, we should divide by 8
    return "8,*" if($ds =~ /bytes/);

    return "1,*";
}#end getScale

