require "rubygems"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec.rb'
  spec.rspec_opts = %w[--color]
end

task :default => :spec