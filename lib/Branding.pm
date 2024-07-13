#!/usr/bin/perl -w
#Branding.pm
#
# This script provides a the branding for Grasshopper
# It and the css can be modified to suit user needs
#
###########################################################################
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

package Branding;

#system includes
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);


sub branding_header {
    my($self,$co,$titlebar,$title,$path) = @_;
    my $tmp;

    $tmp = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<title>'.$titlebar.'</title>
		<meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
			
		<link rel="Shortcut Icon" type="image/x-icon" href="images/favicon.ico" />

        <script type="text/javascript" src="jquery-1.4.2.min.js"></script>
        <script type="text/javascript" src="jquery-ui-1.8.7.custom.jsmin.js"></script>
        <script type="text/javascript" src="jquery.xslt.jsmin.js"></script>
        <script type="text/javascript" src="grasshopper.js"></script>
        
        <link rel="stylesheet" href="jquery-ui-1.8rc3.custom.css" type="text/css" media="all" />
        <link rel="stylesheet" href="grasshopper.css" media="screen" />
	</head>
	<body> 
		<div id="header">
            <h1><br/><a href="index.cgi">'.$title.'</a></h1>
		</div> <!-- end header --> 

		<div id="content-container">
            <div id="content-contents"> 
                <br />
';

    return $tmp;
}#end branding_header

sub branding_footer {
return<<EOF
</div>
</div>
</div>
</div>
</body> 
</html>
EOF
}#end branding_footer

1;
