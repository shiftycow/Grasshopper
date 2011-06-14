/* helpdesk.js
*
*  this file contains all the custom javascript needed by
*  the Grasshopper application. It is largely dependent on jQuery,
*  jQueryUI, and the jQueryXSLT pluggin for DOM manipulation. 
*
****************************************************************************/
/*
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
*/

/* global variables to hold pre-loaded XSL templates */
var host_tree_xsl; //xsl for fomatting the host tree 
var port_info_xsl; //xsl for detailed prot information

var spinner_html = '<div class="spinner"><img src="images/spinner.gif" alt="Loading, please wait" /></div>';


/******* jQuery Extensions **************/

//define an "exists" function to use with jQuery
$.fn.exists = function(){return $(this).length>0;}

/**********************************************/

function download_xslt()
{
    /* This function pre-loads the XSL templates used to transform the return
    *  data from helpdesk.cgi
    *************************************************************************/

    $.get("host_tree.xsl",null, function(data)
                                {
                                    host_tree_xsl = data;
                                });
    $.get("port_info.xsl",null, function(data)
                                {
                                    port_info_xsl = data;
                                });
   }/* end download_xslt */

function show_data(data,xsl_sheet,div)
{
    /* if a string is returned, it's probably the 
    *  login page being shown because the session timed out,
    *  so redirect the user to the main page to log in again
    *******************************************************/
    //alert("showing data");

    if(typeof(data) != "object")
    {
        //window.location = "index.cgi";
        return;
    }

    //alert(data);
    /* otherwise, run the xsl transform on the returned data */
    $(div).xslt({xml: data, xsl: xsl_sheet });

    /* perform zebra striping of the resultant table, if any */
    $("tr:odd").addClass("odd");
    $("tr:even").addClass("even");
}//end show_data

function columns()
{
    /* creates HTML defining the three columns in the layout
    /* this is used to reset the layout to make sure all the
    /* columns are present when switching between 
    /* single and multi-column views
    /******************************************************/
    
    var html = "";

    //column 0 is a special column for 1 column layouts
    html += '<div id="column0">\n';
    html += '   <div id="column1"></div>\n';
    html += '   <div id="column2"></div>\n';
    html += '</div><!--end column 0-->\n';
    
    $("#column_container").html(html);
}//end columns


function load_host_tree(path,node)
{
    /* loads the specified path of the host tree into the
    *  target element
    *
    ***************************************************************************/
    var target = "#"+node+"-child"; //put the subtree into the node's child div
    var parent_li = "#"+node+"-parent";

    //mark the parent as loading
    $(parent_li).addClass("loading");
    $.get("host_tree.cgi?path="+path,null, function(data)
                                {
                                    show_data(data,host_tree_xsl,target);
                                    $(parent_li).removeClass("loading");
                                    toggle_list(node);
                                });
    //toggle_list(node);
}//end load host tree


function toggle_subtree(path,node)
{
    /* toggles the display of a subtree of a node
    *  It loads the subtree dynamically with load_host_tree
    *  if needed and then toggles the display of the list
    *******************************************************/
    //load_host_tree(path,node);

    var parent_li = "#"+node+"-parent";
    
    breadcrumb_trail(path,node);
    //if the subtree is already expanded, just collapse it
    if($(parent_li).hasClass("expanded"))
    {
        toggle_list(node);
    }

    else
    {
        //load_host_tree will display the subtree when the AJAX call returns
        load_host_tree(path,node);
    }
}//end toggle_subtree


function toggle_list(identifier)
{
    /* expands/unexpands an element in a tree
    *
    ******************************************/
    var parent_li = "#"+identifier+"-parent";
    var child_ul = "#"+identifier+"-child";
    
    if($(child_ul).hasClass("active"))
    {
        $(child_ul).hide("blind",{},"",function(){
                                    $(child_ul).removeClass("active");
                                    $(child_ul).addClass("inactive");
                                    
                                    $(parent_li).removeClass("expanded");
                                    $(parent_li).addClass("expandable");
                                 });
    }

    
    if($(child_ul).hasClass("inactive"))
    {
        $(child_ul).show("blind",{},"",function(){
                                    $(child_ul).removeClass("inactive");
                                    $(child_ul).addClass("active"); 
                                   
                                    $(parent_li).removeClass("expandable");
                                    $(parent_li).addClass("expanded");
                                 });    
    }
}//end toggle_list


function breadcrumb_trail(path,node)
{
    /* builds breadcrumb trail html from the given path
    *  and inserts it into the breadcrumb div
    ***************************************************/

    var html = "";
    var path_segments;
    path_segments = path.split("_");
    var tmp_path = "";
    
    var debug_html = "";

    //alert("'"+path_segments+"'");
    $("#breadcrumb_trail").html("");
    
    for (var i in path_segments)
    {
        if(i == 0)
        {
            debug_html += "adding root to trail<br />";
            html += "<a onclick=\"toggle_subtree('_','_')\" class=\"clickable\">All Hosts</a>";
            tmp_path = "_";
        }
        if(i != 0 && path_segments[i] != "")
        {
            tmp_path += "_" + path_segments[i];
            debug_html += "adding path segment '"+path_segments[i]+"' to trail<br />";
            html += " / ";
            html += "<a onclick=\"toggle_subtree('"+tmp_path+"','_')\" class=\"clickable\">";
            html += path_segments[i];
            html += "</a>";
        }
    }

    
    //$("#debug").html(debug_html);
    $("#breadcrumb_trail").html(html);
}//end breadcrumb_trail


function load_port_info(group,hostname,rrd,port_name,description)
{
    $("#port_info").html(spinner_html);
    $.get("port_data.cgi?group="+group+"&hostname="+hostname+"&rrd="+rrd+"&port_name="+port_name+"&description="+description,null, function(data)
            {   
                //$("#column2").html(data);
                show_data(data,port_info_xsl,"#port_info");
            });
}//end load_port_info


function update_graph(graph_name)
{
    //updates the specified graph with it's (presumably changed) data
    var post_data = $("#"+graph_name+"_data").serialize();
    
    var d=new Date();
    var time = d.getTime()
    
    var image_url = "graph.cgi?"+post_data+"&time="+time;
    
    var graph_div = "#"+graph_name+"_graph";

    $(graph_div).html("<img src=\""+image_url+"\" alt=\""+graph_name+"\" />");
    
}//end update graph


