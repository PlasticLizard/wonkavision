require "rubygems"
require "active_support"
require "active_support/hash_with_indifferent_access" unless defined?(HashWithIndifferentAccess)

dir = File.dirname(__FILE__)
["support",
 "plugins",
 "event_path_segment",
 "event",
 "event_context",
 "event_namespace",
 "event_coordinator",
 "event_binding",
 "event_handler",
 "message_mapper/indifferent_access",
 "message_mapper/map",
 "message_mapper",
 "plugins/callbacks",
 "plugins/event_handling",
 "plugins/business_activity",
 "plugins/timeline",
 "acts_as_oompa_loompa",
 "persistence/mongo_mapper_adapter"].each {|lib|require File.join(dir,'wonkavision',lib)}

#require File.join(dir,"cubicle","mongo_mapper","aggregate_plugin") if defined?(MongoMapper::Document)

module Wonkavision

#  def self.register_cubicle_directory(directory_path, recursive=true)
#    searcher = "#{recursive ? "*" : "**/*"}.rb"
#    Dir[File.join(directory_path,searcher)].each {|cubicle| require cubicle}
#  end

  class << self

    attr_accessor :event_path_separator

    def event_coordinator
      @event_coordinator ||= Wonkavision::EventCoordinator.new
    end

    def event_path_separator
      @event_path_separator ||= '/'
    end

    def namespace_wildcard_character
      @namespace_wildcard_character = "*"
    end

    def is_absolute_path(path)
      path.to_s[0..0] == event_path_separator
    end

    def normalize_event_path(event_path)
      event_path.to_s.split(event_path_separator).map{|s|s.underscore}.join(event_path_separator)
    end

    def join (*args)
      args.map!{|segment|normalize_event_path(segment)}
      args.reject{|segment|segment.blank?}.join(event_path_separator)
    end

    def split(event_path)
      event_path.split(event_path_separator)
    end
  end

  class WonkavisionError < StandardError #:nodoc:
  end



end