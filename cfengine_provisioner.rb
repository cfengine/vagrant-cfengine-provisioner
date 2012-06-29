class CFEngineProvisioner < Vagrant::Provisioners::Base

  ######################################################################

  class CFEngineError < Vagrant::Errors::VagrantError
    error_namespace("vagrant.provisioners.cfengine")
  end

  ######################################################################

  class Config < Vagrant::Config::Base
    # Default config values
    CFEngineConfigDefaults = {
      'install_cfengine' => true,
      'am_policy_hub' => true,
      'policy_server' => nil,
      'bootstrap' => true,
      'cfengine_tarfile_url' => nil,
      'cfengine_tarfile_tmpfile' =>  '/tmp/vagrant-cfengine-tarfile.tar.gz',
      'cfengine_files_path' => nil,
      'cfengine_debian_repo_file' => '/etc/apt/sources.list.d/cfengine-community.list',
      'cfengine_debian_repo_line' => 'deb http://cfengine.com/pub/apt $(lsb_release -cs) main',
      'cfengine_yum_repo_file' =>    '/etc/yum.repos.d/cfengine-community.repo',
      'cfengine_yum_repo_url' =>     'http://cfengine.com/pub/yum/',
      'cfengine_repo_gpg_key_url' => 'http://cfengine.com/pub/gpg.key',
    }      

    # Generate the accessors 
    CFEngineConfigDefaults.keys.each do |param|
      eval "attr_accessor :#{param}"
      eval "def #{param}; @#{param} || #{CFEngineConfigDefaults[param].inspect}; end"
    end

    def validate(env, errors)
      super

      errors.add("Invalid cfengine_files_path parameter, must be an existing directory") unless !cfengine_files_path || File.directory?(cfengine_files_path)
      errors.add("Only one of cfengine_tarfile_url or cfengine_files_path must be specified") if cfengine_tarfile_url && cfengine_files_path

      # URL validation happens in prepare.
    end
  end

  ######################################################################

  # Shamelessly copied from Vagrant::Action::Box::Download
  class CFDownloader 
    def initialize(env, url)
      @env = env
      @classes = [Vagrant::Downloaders::HTTP, Vagrant::Downloaders::File]
      @downloader = nil
      @url = url
      instantiate_downloader
    end

    def instantiate_downloader

      # Find the class to use.
      @classes.each_index do |i|
        klass = @classes[i]

        # Use the class if it matches the given URI or if this
        # is the last class...
        if @classes.length == (i + 1) || klass.match?(@url)
          @env[:vm].ui.info I18n.t("vagrant.actions.box.download.with", :class => klass.to_s)
          @downloader = klass.new(@env[:vm].ui)
          break
        end
      end

      # This line should never be reached, but we'll keep this here
      # just in case for now.
      raise Errors::CFEngineDownloadUnknownType if !@downloader

      @downloader.prepare(@url)
      true
    end

    def download_to(f)
      @downloader.download!(@url, f)
    end
  end

  ######################################################################

  def initialize(env, config)
    super
    @logger = Log4r::Logger.new("vagrant::provisioners::cfengine")
  end

  def self.config_class
    Config
  end

  def prepare
    # We download the tarfile, if necessary, during prepare, so during provision!
    # we can just copy it to the VM.
    if config.cfengine_tarfile_url
      @downloader = CFDownloader.new(@env, config.cfengine_tarfile_url)
      @downloader.download_to(File.open(config.cfengine_tarfile_tmpfile, "w"))
    end
  end

  def provision!
    # Determine the type of distro if possible
    @__distro = get_vm_packager

    # First install CFEngine, if requested and necessary
    if !verify_cfengine_installation || config.install_cfengine == :force
      if config.install_cfengine
        add_cfengine_repo
        install_cfengine_package
        unless verify_cfengine_installation
          # TODO: eliminate the error once the proper message for the exception is added to en.yml
          env[:vm].ui.error("CFEngine installation failed, cannot provision host")
          raise CFEngineError, :cfengine_installation_failed
        end
      else
        # TODO: eliminate the error once the proper message for the exception is added to en.yml
        env[:vm].ui.error("CFEngine is not installed, and config.install_cfengine is set to false. Cannot provision host.")
        raise CFEngineError, :cfengine_not_installed
        return
      end
    end

    # Install /var/cfengine files if necessary
    if config.cfengine_tarfile_url
      install_tarfile(config.cfengine_tarfile_tmpfile)
    end
    if config.cfengine_files_path
      install_files(config.cfengine_files_path)
    end
    if config.bootstrap
      if !verify_bootstrap || config.bootstrap == :force
        env[:vm].ui.info("Re-bootstrapping because config.bootstrap is set to 'force'") if config.bootstrap == :force
        bootstrap_cfengine
      end
    end
  end

  # Helper functions

  def verify_cfengine_installation
    env[:vm].ui.info("Checking if CFEngine is already installed in this host.")
    return env[:vm].channel.test("test -d /var/cfengine && test -x /var/cfengine/bin/cf-agent", :sudo => true)
  end

  def verify_bootstrap
    # This only checks that the host has at some point been bootstrapped, it does not check
    # the state of the connection to the hub, the running daemons, or anything else.
    env[:vm].ui.info("Checking if CFEngine has already been bootstrapped.")
    return env[:vm].channel.test("test -f /var/cfengine/policy_host.dat", :sudo => true)
  end

  def add_deb_repo
    env[:vm].ui.info("Adding the CFEngine repository to #{config.cfengine_debian_repo_file}")
    env[:vm].channel.sudo("mkdir -p #{File.dirname(config.cfengine_debian_repo_file)} && /bin/echo #{config.cfengine_debian_repo_line} > #{config.cfengine_debian_repo_file}")
    env[:vm].channel.sudo("GPGFILE=`tempfile`; wget -O $GPGFILE #{config.cfengine_repo_gpg_key_url} && apt-key add $GPGFILE; rm -f $GPGFILE")
  end

  def add_yum_repo
    env[:vm].ui.info("Adding the CFEngine repository to #{config.cfengine_yum_repo_file}")
    env[:vm].channel.sudo("mkdir -p #{File.dirname(config.cfengine_yum_repo_file)} && (echo '[cfengine-repository]'; echo 'name=CFEngine Community Yum Repository'; echo 'baseurl=#{config.cfengine_yum_repo_url}'; echo 'enabled=1'; echo 'gpgcheck=1') > #{config.cfengine_yum_repo_file}")
    env[:vm].ui.info("Installing CFEngine Community Yum Repository GPG KEY from #{config.cfengine_repo_gpg_key_url}")
    env[:vm].channel.sudo("GPGFILE=$(mktemp) && wget -O $GPGFILE #{config.cfengine_repo_gpg_key_url} && rpm --import $GPGFILE; rm -f $GPGFILE")
  end

  def get_vm_packager
    if env[:vm].channel.test("test -d /etc/apt")
      :apt
    elsif env[:vm].channel.test("test -f /etc/yum.conf")
      :yum
    else
      :other
    end
  end

  def add_cfengine_repo
    if @__distro == :apt
      add_deb_repo
    elsif @__distro == :yum
      add_yum_repo
    else
      env[:vm].ui.error("Don't know how to configure the CFEngine package repository in this distribution")
      raise CFEngineError, :unsupported_cfengine_package_distro
    end
  end

  def install_cfengine_package
    env[:vm].ui.info("Installing the CFEngine binary package.")
    if @__distro == :apt
      env[:vm].channel.sudo("apt-get update && apt-get install cfengine-community");
    elsif @__distro == :yum
      env[:vm].channel.sudo("yum -y install cfengine-community")
    else
      env[:vm].ui.error("Don't know how to install the CFEngine package in this distribution")
      raise CFEngineError, :unsupported_cfengine_package_distro
    end
  end

  def install_tarfile(tarfile)
    unless File.exists?(tarfile)
      env[:vm].ui.error("The tarfile #{tarfile} disappeared, cannot install on VM.")
      raise CFEngineError, :tarfile_disappeared
    end
    # For now use the same file in the VM
    env[:vm].ui.info("Copying #{tarfile} to VM")
    env[:vm].channel.upload(tarfile, tarfile)
    # Then untar it on the VM
    env[:vm].ui.info("Unpacking tarfile on VM")
    env[:vm].channel.sudo("cd /var/cfengine && tar zxvf #{tarfile}")
  end

  def install_files(dirpath)
    # Copy the contents of dirpath to /var/cfengine on the VM
    unless File.directory?(dirpath)
      env[:vm].ui.error("The path #{dirpath} must exist and be a directory")
      raise CFEngineError, :invalid_files_directory
    end
    env[:vm].ui.error("The cfengine_files_path option is not yet functional")
    # TODO: not working because scp_connect is protected. best solution
    # would be to add an "options" argument to channel.upload so that
    # we can specify options like :recursive
    #env[:vm].channel.scp_connect do |scp|
    #  scp.upload!(dirpath, '/var/cfengine', :recursive => true)
    #end
  end

  def bootstrap_cfengine
    if config.am_policy_hub
      # For the policy server, config.policy_server is optional
      ipaddr = (config.policy_server.nil? || config.policy_server.empty?) ? get_my_ipaddr : config.policy_server
      if !ipaddr
        env[:vm].ui.error("I couldn't find my IP address for bootstrap, and no policy_server config parameter was specified in the Vagrantfile.")
        raise CFEngineError, :no_bootstrap_ip
      else
        name = "CFEngine policy hub"
      end
    else
      # For clients, config.policy_server is mandatory
      ipaddr = config.policy_server
      if !ipaddr
        env[:vm].ui.error("You need to specify the policy_server config parameter in the Vagrantfile.")
        raise CFEngineError, :no_bootstrap_ip
      else
        name = "CFEngine client"
      end
    end
    env[:vm].ui.info("I am a #{name}, bootstrapping to policy server at #{ipaddr}.")
    status = env[:vm].channel.sudo("/var/cfengine/bin/cf-agent --bootstrap --policy-server #{ipaddr}", :error_check => false) do |type, data|
      output_from_cmd(type, data)
    end
    if status == 0
      env[:vm].ui.info("#{name} bootstrapped successfully.")
    else
      env[:vm].ui.error("Error bootstrapping #{name}.")
      raise CFEngineError, :bootstrap_error
    end
  end

  # Utilities

  def execute_capture(cmd, user_opts={})
    opts = user_opts.merge({:error_check => false})
    stdout = nil
    stderr = nil
    exit_status = env[:vm].channel.execute(cmd, :error_check => false) do |type, data|
      if type == :stdout
        stdout = (stdout||"") + data
      else
        stderr = (stderr||"") + data
      end
    end
    return [exit_status, stdout, stderr]
  end

  def output_from_cmd(type, data)
    # Output the data with the proper color based on the stream.
    color = type == :stdout ? :green : :red
    
    # Note: Be sure to chomp the data to avoid extra newlines.
    env[:vm].ui.info(data.chomp, :color => color, :prefix => false)
  end

  def get_my_ipaddr
    (status, out, err) = execute_capture("ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'")
    @logger.debug("Obtaining host's IP address: status=#{status}, out=#{out}, err=#{err}")
    if status != 0
      env[:vm].ui.error("Error obtaining my IP address: #{err}", :color => :red)
    else
      ipaddr = (out.split)[0]
    end
    ipaddr
  end

end
