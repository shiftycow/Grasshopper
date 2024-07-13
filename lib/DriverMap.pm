#!/usr/bin/perl
#
# DriverMap.pm
# 
# This library provides functions to map device descriptions (sysData) 
# to the driver library that should be used to poll those kinds of hosts
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
#    Michael Harris (mharris@visgence.com)
#    Evan Salazar (sevan@nmsu.edu)
#
##############################################################################

use strict;
package DriverMap;

#system includes
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
use Logger;

my $driver_map_file = GrasshopperConfig::get_config_element("DRIVER_MAP");

my $driver_map = XML::Dumper::xml2pl("$APP_PATH/../$driver_map_file");
my $default_driver = GrasshopperConfig::get_config_element("DEFAULT_DRIVER");

sub find_driver
{
    #maps the specifed system type to it's driver based on the config file
    my ($sys_data) = @_;

    #Logger::log("finding driver");

    foreach(@$driver_map)
    {
        my $candidate_device = $_;

        #we itterate over the keys for candidate devices because, in practice,
        #the number of keys will likely be smaller than the number in $sys_data
        #since the device config is usually sparse.
        #another optimization is that we don't bother with the driver or description tags
        #the theory is that a regex match takes longer than a string comparison, though
        #this should be benchmarked
        while(my ($key, $value) = each %$candidate_device)
        {
            #Logger::log("trying '$key' '$value' against '".$sys_data->{$key}->{'data'}."'");
            if($sys_data->{$key} ne undef && $key ne "driver" && $key ne "description" && $sys_data->{$key}->{'data'} =~ /$value/)
            {
                #if we find a matching key/value pair, use the specified driver
                my $driver = $candidate_device->{"driver"};
                return $driver;
            }
        }#end match checking

    }#end foreach device
    
    #if we didn't find a matching device, use the default driver
    return $default_driver;
}#end find_driver


1;

