#!/usr/bin/perl
#
# dependency_check.pl
# 
# This file includes all of the Grasshopper libraries to check 
# that the necessary dependencies are installed on the target system
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

#system includes

#from polling_daemon.pl
use XML::Dumper;
use IO::Socket;
use File::Spec;
use Storable;

#from host_db_daemon.pl
use English;

#from graph.cgi
#use CGI;
use RRDs;
use Digest::MD5;

#from port_data.cgi
use POSIX;

#from Branding.pm
use CGI::Carp;

#from Pollers.pm
use SNMP;
use RRD::Simple;

#from ReadRRD.pm
use Data::Dumper;



# if any of the library includes fail, the program will error out
print "dependency check completed successfully!\n";
