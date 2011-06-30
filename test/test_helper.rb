$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require 'bundler'
Bundler.setup

require 'active_support/test_case'
require "shoulda"
require "mocha"
require "bson"


dir = File.dirname(__FILE__)
require File.join(dir,"..","lib","wonkavision")

require "test_event_handler"

$test_dir = dir
    
