#!/usr/bin/perl
#
# index.cgi
#
# This page provides the main interface to the Grasshopper Application
#
###############################################################################
#
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
##############################################################################

use strict;

use lib "../lib";

#system includes
use CGI;
use XML::Dumper;

#local incldues
use Branding;
use GrasshopperConfig;

my $co = new CGI;

# action handlers
my $action = $co->param('action');

main() if $action eq undef;

sub main
{
    my $PAGE_TITLE = GrasshopperConfig::get_config_element("WEB_PAGE_TITLE");
    my $host_path = $co->param('host_path'); #a path for jumping to a certain spot on the host tree 
    $host_path = "_" if($host_path eq undef);

    print $co->header("text/html");
    my $branding = Branding::branding_header('','',$PAGE_TITLE,$PAGE_TITLE,'http://netreg.nmsu.edu/branding/');
    my $branding_footer = Branding::branding_footer();

#Code for front page;
    my $html=<<EOF;
    $branding
        <script type="text/javascript" src="grasshopper.js"></script>
        <script type="text/javascript">
        <!--
            /*pre load the xslt sheets so they don't have to be requested all the time*/
            download_xslt();
        -->
        </script>

        <div id="column_container">
            <div id="column1">
                <h1 class="center">Hosts</h1>
                <div id="_-child"></div><!--root node ('_' is our path delimeter)-->
            </div><!--end column 1-->
        
            <div id="column2">
                <h1 class="center">Grasshopper Network Traffic Monitor</h1>
                <div id="breadcrumb_trail"></div><!--end breadcrumb trail-->
                <div id="debug" class="ui-widget ui-state-error" style="width: 600px; margin: auto; display: none"></div>
                
                <div id="port_info">
                    <!--this content is the starter splash page, it will be replaced later-->
                    
                    <h4>Welcome to Grasshoppper! Use the host tree to the left to display information for specific switches or hosts</h4>
                    <br /> 
                    
                    <!--end splash content-->
                </div><!--end port_info--> 
                
            </div><!--end column 2-->
            

        </div><!--end column container-->
        <div class="center" style="margin-top: 75px">
            <img src="images/grasshopper-logo.png" alt="powered by Grasshopper" />
        </div>
        
        <!--script to load the initial page view-->
        <script type="text/javascript">
            toggle_subtree("$host_path","_");
        </script>

        $branding_footer
EOF

        print $html;
}#end main
