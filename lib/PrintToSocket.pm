#!/usr/bin/perl
#
# Provides a function to print to a local socket on a specific port
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

package PrintToSocket;

#system incldues
use IO::Socket;

#local includes
use Logger;

sub print_to_socket
{
    #prints a message to the control socket
    #if $open is specified, it returns an open socket
    #otherwise, it closes the socket after sending the message
    #

    #normally, it exits the program if it cannot print
    #if the noexit flag is set, it just returns so that the caller
    #can do error handling
    #

    my ($message,$port,$open,$noexit) = @_;
    my $sock = new IO::Socket::INET (
            PeerAddr => 'localhost',
            PeerPort => $port,
            Proto => 'tcp',
            );
    #print "socket open, printing\n";
    if($sock eq undef)
    {
        return undef if($noexit ne undef);
        Logger::log("CANNOT PRINT TO SOCKET! Exiting");
        exit(1);
    }
    
    #print "socket open, printing\n";
    print $sock $message;

    return $sock if($open ne undef);
    close($sock);
    return 1;
}#end print_to_socket

1;
