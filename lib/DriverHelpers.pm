#!/usr/bin/perl
#
# DriverHelpers.pm
#
# This file contains helper functions for the pollign drivers.
# These include XML reading/writing, string parsing, etc...
#
# This file does not need to be modified in order to create new drivers
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
package DriverHelpers;

sub xml_dump
{ 
    #creates an xml file from the given data
    #
    
    my ($ifdata,$rrdpath,$xml) =@_;
    my  $xmlfile = $rrdpath ."index_". $ifdata->{'ifIndex'} . ".xml";

    #create the directory if it doesn't already exist
    `mkdir -p $rrdpath` unless (-e $xmlfile);

    #Logger::log("Creating XML file $xmlfile");
    open FILE,">>$xmlfile";
    print FILE $xml;
    close FILE;
}#end data dump

sub format_mac 
{
    #formats a mac address to look like xx:xx:xx:xx:xx:xx
    my ($mac) = @_;
    $mac =~(s/"//g);
    $mac = lc($mac);
    my @macarray = split(/ /,$mac);
    for(my $i=0;$i<6;$i++)
    {
        if( length($macarray[$i]) == 1)
        {
            $macarray[$i] = "0" . $macarray[$i];
        }
    }
    return join(":",@macarray);
}#end format_mac

1;
