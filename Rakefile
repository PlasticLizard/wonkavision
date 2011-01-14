require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/testtask'

require File.expand_path('../lib/wonkavision/version', __FILE__)

desc 'Builds the gem'
task :build do
  sh "gem build wonkavision.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install wonkavision-#{Wonkavision::VERSION}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Wonkavision::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{Wonkavision::VERSION}"
  sh "gem push wonkavision-#{Wonkavision::VERSION}.gem"
end


Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
end

task :default => :test
