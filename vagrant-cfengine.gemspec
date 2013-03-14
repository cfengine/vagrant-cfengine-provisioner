# -*- encoding: utf-8 -*-
#
Gem::Specification.new do |gem|
  gem.authors       = ['Diego Zamboni']
  gem.email         = ['diego@zzamboni.org']
  gem.description   = %q{"This provisioner provides Vagrant the ability to use CFEngine to configure a virtual machine."}
  gem.summary       = %q{"This provisioner provides Vagrant the ability to use CFEngine to configure a virtual machine.

  This provisioner will also install CFEngine if needed (only supported on RedHat, CentOS, Debian and Ubuntu for now), so you can use it on a plain base box, like the ones found at https://github.com/mitchellh/vagrant/wiki/Available-Vagrant-Boxes."}
  gem.homepage      = "https://github.com/cfengine/vagrant-cfengine-provisioner"

  gem.add_dependency "vagrant"
  gem.add_development_dependency "rspec"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "vagrant-cfengine"
  gem.require_paths = ["lib"]
  gem.version       = "0.1"
end
