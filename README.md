# CFEngine provisioner for Vagrant

## Please do not use this provisioner. Use Vagrant 1.2 or later, which includes already a newer version of the provisioner. This is kept here for historical purposes.

This provisioner provides Vagrant the ability to use CFEngine
to configure a virtual machine.

This provisioner will also install CFEngine if needed (only
supported on RedHat, CentOS, Debian and Ubuntu for now), so
you can use it on a plain base box, like the ones found at
<https://github.com/mitchellh/vagrant/wiki/Available-Vagrant-Boxes>.

## Installation

To use it, put `cfengine_provisioner.rb` in the "lib" directory of
your vagrant installation (the same one where vagrant.rb is located)
or somewhere else in your Ruby library path. You can also put it in
the same directory as your Vagrantfile, and change the `require` at
the top to be like this (note the dot-slash at the beginning):

    require './cfengine_provisioner.rb'

This is only temporarily, we'll soon package it as a proper Vagrant
plugin.

## Usage

For now, all the documentation about the parameters is in the provided
Vagrantfile samples. You can find them in the samples/ directory.

`samples/community/` contains a simple Vagrantfile that instantiates a
single VM and configures it as a policy hub.

`samples/enterprise/` contains a more complex example that creates a
hub, four clients, and installs CFEngine Enterprise on all of them
(you need to provide your own Enterprise packages, you can get them
free for up to 25 nodes at http://cfengine.com/25free ).

`samples/master/` contains a Vagrantfile that downloads, compiles
and installs the latest version of CFEngine from the github repository.
This is useful for running tests on the latest version of the code.

## Feedback

If you have any comments, please contact me through Twitter
[@zzamboni](http://twitter.com/zzamboni) or look for me in the
[#cfengine IRC channel](http://webchat.freenode.net/?channels=cfengine).
