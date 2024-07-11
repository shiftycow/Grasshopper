Grasshopper - Fast SNMP data gathering and graphing

Copyright 2010-2011 - New Mexico State University Board of Regents

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>

Contributing Authors:
    Michael Harris (mharris@visgence.com)
    Evan Salazar (sevan@nmsu.edu)

-------------------------------------------------------------------------------

Table of Contents:

    Section 0.......About GrasshopperNMS
    Section 1.......Dependencies
    Section 2.......System Considerations
    Section 3.......Checkout/Installation
    Section 4.......Configuration
    Section 4.1.....|---Single Server
    Section 4.2.....|---Cluster
    Section 5.......Usage

-------------------------------------------------------------------------------
Section 0 - About GrasshopperNMS

--
-------------------------------------------------------------------------------
--
Section 1 - Dependencies

Grasshopper requires the folowing dependencies in order to run: 

Perl Core Modules:
    POSIX
    CGI
    IO::Socket
    Data::Dumper
    Storable

Other Perl Modules (might have to get from CPAN)
    RRD::Simple
    XML::Dumper
    XML::LibXML - not needed in this release
    XML::LibXSLT - not needed in this release
    SNMP

System
    rrdtool (http://www.mrtg.org/rrdtool/)
    NetSNMP
    Perl
    Cron or similar task-scheduling program
    support for /dev/shm or other RAM disk and at least 1GB of available space

--
-------------------------------------------------------------------------------
--
Section 2 - System Considerations

Grasshopper is a heavily multi-threaded process. As such, it is recommend that
servers running the GrasshopperNMS have at least 4 availble CPUs. It is also 
recommended that the data store be located on a high-performace storage
device - either a Solid State Disk or a high-performance NAS/SAN.

GrasshopperNMS also uses a memory cache to store temporary polling data. 
Usually, this would be placed in /dev/shm, so there needs to be enough space.

--
-------------------------------------------------------------------------------
--
Section 3 - Checkout/Installation

The GrasshopperNMS should be given it's own directory and user. In these
instructions, /home/grasshopper and the user `grasshopper` are used.

0. User setup
    sudo adduser grasshopper
    sudo su - grasshopper

1. Git Checkout
    TODO: these instructions

2. Download
    cd /home/grasshoper
    wget grasshoppernms.org/files/grasshopper.tar.gz
    <untar into .>

3. make install
    TODO: write install script for automatic configuration

--
-------------------------------------------------------------------------------
--
Section 4 - Configuration

