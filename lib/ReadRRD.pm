#!/usr/bin/perl
#
# Pollers.pm
#
# This module provides various polling methods for getting specific
# data from equipment and saving it to disk or database
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
package ReadRRD;

#system includes
use RRD::Simple;
use RRDs;
use XML::Dumper;
use Data::Dumper;
use IO::Socket;

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
my $db_port = GrasshopperConfig::get_config_element("DB_SERVER_PORT");

sub last_updated
{
    #returns a timestamp of when the RRD was last updated
    
    my ($rrdfile) = @_;

    my $time = RRDs::last $rrdfile;
    
    return $time;
}#end get_info

sub get_stats
{
    my($rrdfile,$dsid,$scale,$si_units) = @_;


    $scale = "1,*" unless $scale;

    my(@args) = (
	    "/dev/null",
	    "DEF:ds0=$rrdfile:$dsid:AVERAGE",
	    "DEF:ds1=$rrdfile:$dsid:MAX",
	    "CDEF:sds0=ds0,$scale",
	    "CDEF:sds1=ds1,$scale",
	    "PRINT:sds0:AVERAGE:\%lf",
	    "PRINT:sds1:MAX:\%lf",
	    "PRINT:sds0:LAST:\%lf" );

    my ($mmax, undef, undef) = RRDs::graph @args;

    my $portdata = {};	

    if($si_units) 
    {
	    $portdata->{'in_cur'} = si_unit($mmax->[2]) . getUnit($dsid);
	    $portdata->{'in_avg'} = si_unit($mmax->[0]) . getUnit($dsid);
	    $portdata->{'in_max'} = si_unit($mmax->[1]) . getUnit($dsid);
    }

    else 
    {
	    $portdata->{'in_cur'} = $mmax->[2];
	    $portdata->{'in_avg'} = $mmax->[0];
	    $portdata->{'in_max'} = $mmax->[1];
    }

    return $portdata;
}#end get_stats

sub get_dslist
{
    my($rrdfile) = @_;
    
    my $rrd = RRD::Simple->new( file => $rrdfile );
    my $info = $rrd->info($rrdfile);
    
    my @dslist;

    while ( my ($key, $value) = each(%{$info->{'ds'}}) ) 
    {
        push(@dslist,$key);
    }

    @dslist = sort(@dslist);

    return \@dslist;
}#end get_dslist

sub si_unit
{
    my($value, $bytes) = @_;
    my $precision = 2;
    return sprintf("%0.${precision}f ",$value) if ($value eq "?" || lc($value) eq "nan" || $value == 0);

    my(@symbol) = ('a', 'f', 'p', 'n', '&#181;', 'milli',
                   '',
                   'k', 'M', 'G', 'T', 'P', 'E');
    my($symbcenter) = 6;


    my($digits) = int(log(abs($value))/log(10) / 3);

    my($magfact);
    if ($bytes) 
    {
        $magfact = 2 ** ($digits * 10);
    } 
    
    else 
    {
        $magfact = 10 ** ($digits * 3.0);
    }

    if ((($digits + $symbcenter) > 0) && (($digits + $symbcenter) <= $#symbol)) 
    {
        #return ($value/$magfact, $symbol[$digits + $symbcenter]);
        my $magvalue = $value = sprintf("%0.${precision}f",($value/$magfact));
        return "$magvalue " . ($symbol[$digits + $symbcenter]);
    }

    else
    {
	    $value = sprintf("%0.${precision}f", $value);
        #return ($value, '');
        return "$value ";
    }
}#end si_unit

sub getUnit() 
{
    my ($ds) = @_;
    
    return "bits/sec" if($ds =~ /bytes/);
    return "pkts/src" if($ds =~ /cast/);
    return "errors/src" if($ds =~ /errors/);
}#end getUnit


1;
