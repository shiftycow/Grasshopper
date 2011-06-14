#!/usr/bin/perl
#
# Forms.pm
#
# This file provides functions for printing common HTML forms
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

package Forms;

use strict;

sub form_input_select
{
    # This function prints a <select> input element given an array of values
    # Its parameters are a list of options, the name of the element, and
    # the element's ID#
    #
    # $options should be an arrayref to a nested set of arrays, 
    # where $options[i][0] is the option value and $options[i][1] is the option label
    # *this kind of data structure requires special care when fetching it from the
    # database using fetchrow_arrayref. See TicketData::get_summaries() or similar
    # for implementation details

    my ($id,$name,$options,$default) = @_;

    #parse out the options list and build an array
    #my @options = split(/,/,$options);

    my $html;
    $html .= "<select name=\"$name\" id=\"$id\">\n";
    foreach my $option (@$options)
    {
        if(lc $default eq lc $option->[0])
        {
            $html .= "<option value=\"".$option->[0]."\" selected=\"selected\">".$option->[1]."</option>\n";
        }
        else
        {
            $html .= "<option value=\"".$option->[0]."\">".$option->[1]."</option>\n";
        }
    }
    $html .= "</select>\n";

    return $html;
}#end print select

sub form_input_checklist
{
    # Prints a checklist from the given comma-separated list
    my ($id,$name,$type,$options,$default) = @_;

    return undef if($type ne "checkbox" and $type ne "radio");
    
    #my @options = split(/,/,$options);
    my $html;
    $html .= "<ul id=\"$id\" class=\"checklist\">\n";
    foreach my $option (@$options)
    {
        if($default eq $option)
        {
            $html .= "<li><input id=\"$id"."_$option\" name=\"$name\" type=\"checkbox\" value=\"$option\" checked=\"true\">$option</li>\n";
        }
        else
        {
            $html .= "<li><input id=\"$id"."_$option\" name=\"$name\" type=\"checkbox\" value=\"$option\">$option</li>\n";
        }
    }
    $html .= "</ul>\n";

    return $html;
}#end input checklist

sub form_input_radio
{
    #prints a radio list of the given options
    #
    
    my ($id, $name, $options, $default) = @_;

    my $html;
    $html .= "<ul id=\"$id\" class=\"radio_list\">\n";
    foreach my $option (@$options)
    {
        if($default eq $option->[0])
        {
            $html .= "<li><input id=\"$id"."_$option\" name=\"$name\" type=\"radio\" value=\"".$option->[0]."\" checked=\"true\">".$option->[1]."</li>\n";
        }
        else
        {
            $html .= "<li><input id=\"$id"."_$option\" name=\"$name\" type=\"radio\" value=\"".$option->[0]."\">".$option->[1]."</li>\n";
        }
    }
    $html .= "</ul>\n";
}#ned form input radio

1;
