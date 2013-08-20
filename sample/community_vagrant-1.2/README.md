# Sample Vagrantfile for setting up CFEngine + Design Center

This Vagrantfile only works with Vagrant 1.2 or later, which include the new CFEngine provisioner. This file will set up an Ubuntu 12.04/64bit system, install the latest CFEngine Community package, and check out the Design Center repository under `/var/cfengine/design-center/`. It will bootstrap the host to itself, setting it up as a policy server.
