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
    
class StatStore < Wonkavision::Analytics::Persistence::Store
  attr_reader :data, :query
    
  def initialize(data)
    @data = data
  end
  def execute_query(query, &block)
    @query = query
    if block_given?
      @data.each do |record|
        yield record
      end
    else
      @data
    end
  end

  def each(query, &block)
    @query = query
    @data.each do |record|
      yield record
    end
  end
end

