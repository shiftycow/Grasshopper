#!/usr/bin/perl
#
# host_tree.cgi
#
# This script traverses the host tree and returns the top-level
# elements from each path in XML
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

#system includes
use XML::Dumper;
use CGI;

#local includes
use lib "../lib";
use GrasshopperConfig;
use GrasshopperAPI;

my $co = new CGI;

#construct a path for navigating the host database
my $path_string = $co->param('path');
$path_string = $ARGV[0] if($path_string eq undef);

$path_string = "_" if($path_string eq undef);

#my $host_tree_xml = GrasshopperConfig::get_config_element("HOST_DATABASE_XML");

#read in the host tree
#my $database = XML::Dumper::xml2pl($host_tree_xml);

my $nodes_xml = GrasshopperAPI::get_host_db_nodes($path_string);

print $co->header("text/xml");

print $nodes_xml;

