require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  require File.dirname(__FILE__) + "/lib/wonkavision/version"

  Jeweler::Tasks.new do |s|
    s.name = "wonkavision"
    s.version = Wonkavision::VERSION
    s.summary = "Simple Business Activity Monitoring (BAM) for Mongo Mapper"
    s.description = "BAM! BAM! BAM BAM!"
    s.email = "hereiam@sonic.net"
    s.homepage = "http://github.com/PlasticLizard/wonkavision"
    s.authors = ["Nathan Stults"]
    s.has_rdoc = false #=>Should be true, someday
    s.extra_rdoc_files = ["README.rdoc", "LICENSE.txt"]
    s.files = FileList["[A-Z]*", "{bin,lib,test}/**/*"]

    s.add_dependency('activesupport', '>= 2.3')

    s.add_development_dependency('shoulda', '2.10.3')
  end

  Jeweler::GemcutterTasks.new

rescue LoadError => ex
  puts "Jeweler not available. Install it for jeweler-related tasks with: sudo gem install jeweler"

end

Rake::TestTask.new do |t|
  t.libs << 'libs' << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'test'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :test