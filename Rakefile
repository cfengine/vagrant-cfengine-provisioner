require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :spec => :test

desc "run all functional specs in this environment"
RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = 'spec/*_spec.rb'

  t.rspec_opts = [ 
    '--format', 'documentation',
    #  This is only really needed once - we can remove it from all the specs
    '--require ./spec/spec_helper.rb',
    '--color',
  ]
end

