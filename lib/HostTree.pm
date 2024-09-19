#!/usr/bin/perl
#
# HostTree.pm 
#
# Provides functions for traversing, processing and extracting 
# information from the Grasshopper Host Database
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

package HostTree;

#system includes
use File::Spec;

#This script could be called from cron or the web, so we need to find it's 
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


sub get_nodes
{
    #
    # returns nodes that can be sent to the web interface
    # this function is meant to provide high-level information nodes
    # and will not return the entire subtree of the given path
    #

    my ($original_database,$path_string) = @_;
    
    $path_string = "_" if($path_string eq undef);

    my $walker = $original_database;
    my @path = split(/_/,$path_string);
    
    my $return_nodes;

    #traverse the database to get the subtree we're interested in
    $walker = $walker->{'root'};
    foreach (@path)
    {
        my $node = $_;
        $walker = $walker->{'child'}->{"$node"} if($node ne undef);
    }
    

    #if the database has no children, we've reached a leaf, so return the data
    if(ref($walker->{'child'}) eq undef)
    {
        #print "database: '$database'\n";
        
        #check the node's description, if it's an rrdPath, we have to do
        #something special
        if($walker->{'description'} eq "rrdPath")
        {
            #generate a list of interfaces based on the rrd directory
            $return_nodes = rrd_list($walker->{'data'},$path_string);
        }

        else
        {
            $return_nodes->{'node'}->{'type'} = "leaf";
            $return_nodes->{'node'}->{'data'} = $walker->{'data'};
            $return_nodes->{'node'}->{'description'} = $walker->{'description'};
        }
    }#end leaf node

    #otherwise, return the children of the node
    else
    {
        $walker = $walker->{'child'};
        
        my @keys = keys %$walker;
        #print "children: @keys\n";
        foreach(@keys)
        {
            my $node_name = $_;
            
            $return_nodes->{$node_name}->{"type"} = "subtree";
            $return_nodes->{$node_name}->{"type"} = "leaf" if($walker->{$node_name}->{'child'} eq undef);
            $return_nodes->{$node_name}->{"data"} = $walker->{$node_name}->{'data'};
            $return_nodes->{$node_name}->{"action"} = $walker->{$node_name}->{'action'};
            $return_nodes->{$node_name}->{"path"} = $path_string."_".$node_name;
            $return_nodes->{$node_name}->{"description"} = $walker->{$node_name}->{'description'};
            $return_nodes->{$node_name}->{"alias"} = $walker->{$node_name}->{'alias'};
	    $return_nodes->{$node_name}->{"sort_key"} = $walker->{$node_name}->{'sort_key'};
        }
    }

    #print "walker: $walker\n";
    #print "original_db: $original_database\n";
    
    return $return_nodes;
}#end get_nodes

sub rrd_list
{
    #
    #returns a list of graphs based on the RRDs that exist for a certain host
    #
    my ($rrd_path,$path_string) = @_; 
    
    #fully qualify the rrd path so that ls works
    my $full_rrd_path = "$APP_PATH/../data/grasshopper_data/$rrd_path";
    my $return_nodes = (); 
    my @ls = `ls -1 $full_rrd_path`;
    
    foreach(@ls)
    {   
        my $rrd = $_;
        chomp $rrd;
        $return_nodes->{$rrd}->{"type"} = "leaf"; #these are unexpandable nodes
        $return_nodes->{$rrd}->{"data"} = $rrd;
        $return_nodes->{$rrd}->{"description"} = "port";
        $return_nodes->{$rrd}->{"action"} = "load_graph('$rrd_path/$rrd');";
        #$return_nodes->{$rrd}->{"action"} = "load_graph('$rrd_path"."_"."$rrd');";
    }   
    
    return $return_nodes;
}#end iterface list

1;
