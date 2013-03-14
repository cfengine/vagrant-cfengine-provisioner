require File.join(File.dirname(__FILE__), '..', 'lib', 'vagrant_init.rb')
require 'tmpdir'

describe CFEngineProvisioner do
  # Set up the vagrant file
  before(:all) do
    rootdir = File.join(File.dirname(__FILE__),'..')
    @tempdir = Dir.tmpdir
    vagrantfile = <<-HERE.gsub(/^ {6}/, '') 
      require '#{rootdir}/lib/vagrant_init.rb'
      Vagrant::Config.run do |config|
        config.vm.define :cfhub do |hub_config|
          hub_config.vm.box = "lucid32"
          hub_config.vm.box_url = "http://files.vagrantup.com/lucid32.box"
          hub_config.vm.network :hostonly, "10.1.1.10"
          hub_config.vm.provision CFEngineProvisioner do |cf3|
          end
        end
      end
    HERE
    # create new Vagrantfile in ../tmp
    File.open(File.join(@tempdir,"Vagrantfile"), "w") {|f| f.write(vagrantfile) }
    Dir.chdir(@tempdir)
  end
  let(:vagrant_env) { ::Vagrant::Environment.new(:cwd => @tempdir) }

  it 'should be available as a provisioner' do
    pending('Need to validate that it is being loaded by vagrant somehow')
  end
end
