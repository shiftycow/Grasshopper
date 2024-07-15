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

Ubuntu 22.04
    sudo apt install build-essential rrdtool snmp libsnmp-base libsnmp-perl apache2 libxml-dumper-perl libsnmp-perl librrds-perl libcgi-pm-perl snmp-mibs-downloader
    sudo cpan install RRD::Simple


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

1. Install system dependencies (For ubuntu 22.04 use command above)

2. install mibs
    sudo sed -i 's/mibs :/# mibs :/g' /etc/snmp/snmp.conf

3. User setup
    sudo adduser grasshopper
    sudo su - grasshopper

4. Git Checkout
    git clone https://github.com/shiftycow/Grasshopper.git grasshopper

5. Copy config examples to configs
    cd ~/grasshoper/conf
    cp grasshopper.conf.example grasshopper.conf
    cp grasshopper-apache.conf.example grasshopper-apache.conf
    cp hosts.lst.example host.lst

5. Run dependencie test scrip to veriy everything needed is installed
    perl ~/grasshopper/cli/test_scripts/dependency_check.pl

--
-------------------------------------------------------------------------------
--
Section 4 - Configuration

# Run the following as root or with sudo

1. Enable CGI in apache2
    a2enmod cgid

2. (Ubuntu) add user to www-data group
    usermod -aG www-data grasshopper

3. Symbolic link grasshopper data to /var/www/html
    cd /var/www/html/
    ln -s /home/grasshopper/grasshopper/

4. Symbolic link grasshoper config to site-enabled
    cd /etc/apache2/sites-enabled/
    ln -s /home/grasshopper/grasshopper/conf/grasshopper-apache.conf

5. Modify http conf as needed for virutal host domain and authors

6. make sure /dev/shm/grasshopper_swap exist and is owned by grasshopper TODO: check what happends on reboot 
    mkdir -p /dev/shm/grasshopper_swap
    chown grasshopper:grasshoper /dev/shm/grasshopper_swap

7. modify grasshoper/conf/grasshoper.conf, Most important add SNMP community, swap location above can be moved

8. Add line in grasshoper/docs/grasshopper.crontab to grasshoper user's crontab


