vagrant-cfengine-provisioner
============================

CFEngine provisioner plugin for Vagrant.

For now, test at your own risk. Look at sample/Vagrantfile for
sample usage and the accepted configuration parameters.

To use this, put cfengine_provisioner.rb in the vagrant "lib"
directory (the same one where vagrant.rb is located) or somewhere else
in your Ruby library path. This is only temporarily, we'll soon
package it as a proper Vagrant plugin.

If you have any comments, please send email to Diego Zamboni
<diego.zamboni@cfengine.com>, @zzamboni on Twitter.
