#!/bin/bash

# Type is "hub" or "client" (actually anything other
# than "hub" is considered as a client)
TYPE=$1

# If /var/cfengine exists, do nothing, assume it's installed already
if [[ -d /var/cfengine ]]
then
    exit 0
fi

# The PKGDIR variable should be the location of the 
# packages *IN THE VM* - the current directory is
# mapped to /vagrant in the VM, so you should keep
# this mapping into account.

########
# Configure these variables according to the distro
# installed in the VM.

# For RPM/yum
#PKGDIR=/vagrant/nova-2.2.2/rhel_6_x86_64
#CMD="rpm -ivh"
# For Ubuntu/apt
PKGDIR="/vagrant/nova-2.2.2/ubuntu-12.04-amd64/"
CMD="dpkg --install"

# End config here
#########

# This assumes there are only two packages in PKGDIR.
# You should specify the filenames if this is not the case.
PKG1=$(ls $PKGDIR/cfengine-nova_2.2.2*)
PKG2=$(ls $PKGDIR/cfengine-nova-expansion_2.2.2*)

# Install the base Enterprise package
$CMD $PKG1

# Install the expansion pack on the hub only
if [[ "$TYPE" == "hub" ]]
then
    $CMD $PKG2
fi
