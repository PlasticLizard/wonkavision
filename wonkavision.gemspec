# encoding: UTF-8
require File.expand_path('../lib/wonkavision/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'wonkavision'
  s.homepage = 'http://github.com/PlasticLizard/wonkavision'
  s.summary = 'Messaging support library'
  s.require_path = 'lib'
  s.authors = ['Nathan Stults']
  s.email = ['hereiam@sonic.net']
  s.version = Wonkavision::VERSION
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,test}/**/*") + %w[LICENSE.txt README.rdoc CHANGELOG.rdoc]

  s.add_dependency 'activesupport', '>= 2.3'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'shoulda',           '~> 2.11'
  s.add_development_dependency 'mocha'
end

