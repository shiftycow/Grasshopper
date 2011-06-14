#!/usr/bin/perl
# log_rotate.pl
#
# This script rotates Grasshopper log files
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
use File::Spec;

#this script could be called from cron, so we need to find it's 
# path to make it portable
my $APP_PATH;

BEGIN
{
        $APP_PATH = File::Spec->rel2abs($0);
            (undef, $APP_PATH, undef) = File::Spec->splitpath($APP_PATH);
}

use lib "$APP_PATH/../lib";

#local includes
use Logger;

my $action = lc $ARGV[0];

#should we force the rotate?
my $force = undef;

$force = "[forced]" if($action eq "force");

print "Grasshopper log rotate script running... $force\n";
Logger::rotate($force);
print "...finished!\n";

exit(0); #exit successfully

