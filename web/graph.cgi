#!/usr/bin/perl
#
# graph.cgi
# 
# This script renders an RRD into a graph and returns the resulting 
# .png image to the browser.
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
use RRDs;
use Digest::MD5  qw(md5_hex);
#local includes
use Logger;

my $co = new CGI;

my $action = $co->param('action');

main() if($action eq undef);
graph() if($action eq "graph");

sub main
{
    #print $co->header("text/html");
    graph(); 
}#end main

sub graph
{

    my $debug = $co->param('debug');
   
    #This is for CLI testing only 
    my $rrd_path = $co->param('rrd_path');
    $rrd_path = "zuhl/zuhl-sa-feed-192-2/index_1.rrd" unless $rrd_path;


    #Set Defaults for all parameters, These could come from the config if needed
    my $base = $co->param('base');
    $base = 1024 unless $base;

    my $range = $co->param('range');
    $range = 151200 unless $range;
    
    my $scale = $co->param('scale');
    $scale = "8,*" unless $scale;
    
    my $width = $co->param('width');
    $width = 500 unless $width;
    
    my $height = $co->param('height');
    $height = 200 unless $height;

    my $yaxis = $co->param('yaxis');
    $yaxis = 'Bits per Second' unless $yaxis;

    my $ds_list = $co->param('ds-list');
    $ds_list = "bytesInPerSec,bytesOutPerSec" unless $ds_list;
    
    my $line_list = $co->param('line-list');
    $line_list = "AREA,LINE1" unless $line_list;
    
    my $color_list = $co->param('color-list');
    $color_list = "00cf00,002a97" unless $color_list;
    
    my $label_list = $co->param('label-list');
    $label_list = "Average Bytes In,Average Bytes Out" unless $label_list;


    my $RRD_DIR = "../data/grasshopper_data";

    #generate a PNG from the RRD
    #Use the time to keep RRD files unique, may change to a hash
    my $time = time();
    my $png_filename = "/tmp/" . md5_hex("$rrd_path$ds_list") . ".png"; # a '-' as the filename send the PNG to stdout
    my $rrd = "$RRD_DIR/$rrd_path";
     

    #Generage rrd rules from DS List
    my (@defs,@cdefs,@lines,@vrules);    
    my (@lines)  = split(',',$line_list);
    my (@colors) = split(',',$color_list);
    my (@lables) = split(',',$label_list);

    my $i = 0;
    my $ds;
    foreach $ds (split(',',$ds_list)) {
	$defs[$i]  = "DEF:$ds=$rrd:$ds:AVERAGE"; 
	$cdefs[$i] = "CDEF:s$ds=$ds,$scale";
	$lines[$i] = "$lines[$i]:s$ds#$colors[$i]:$lables[$i]";

	$i++;
    }

    my (@vrules)= ("VRULE:1246428000#ff0000:");
    
    #Create Args Array from Arrays
    my (@args) = ($png_filename,
		    "-a", "PNG",
		    "-r",
		    "-l", "0",
		    "--base",		$base,
		    "--start",		"-$range",
		    '--vertical-label', $yaxis,
		    '--width',          $width,
		    '--height',         $height,
		    @defs,@cdefs,@lines,@vrules);
    
    RRDs::graph(@args); 
    
    #If we have an error print the args, Need to change to an Image down the road
    if (my $error = RRDs::error) {
     
	print $co->header("text/html");
	print("Unable to create graph: $error\n");
        print("rrd graph: ".join(' ', @args)."\n");
	exit(); 
   }

    #Display the args if debug is on
    if($debug eq 1) {
	print $co->header("text/html");
        print("rrd graph: ".join(' ', @args)."\n");
	exit(); 
    }


    #Open the image and read to a var
    my $res = '';
    my($stuff,$len);
    open(IMG,$png_filename);
    binmode(IMG);
    while ($len = read(IMG, $stuff, 8192)) {
	$res .= $stuff;
    }
    close(IMG);
    unlink($png_filename);
    
    
    #print the image to the browser
    print $co->header("image/png");
    binmode STDOUT;
    print $res;
}#end graph
