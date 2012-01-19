# encoding: UTF-8
# Taken almost verbatim from https://github.com/jnunemaker/mongomapper/blob/master/lib/mongo_mapper/connection.rb
require 'uri'
require "wonkavision/analytics/persistence/store/mongo_store_common"


module Wonkavision
  module Analytics
    module Persistence
      module MongoCommon

        attr_reader :connection, :database_name
        attr_accessor :safe

        def database_name=(database_name)
          @database_name = database_name
          @database = nil
        end
             
        # @api public
        def database
          @database ||= database_name ? connection.db(database_name) : nil
        end
        
        def connect(options={})
          options = options.dup
          host = options.delete(:host) || '127.0.0.1'
          port = options.delete(:port) || 27017
          username = options.delete(:username)
          password = options.delete(:password)
          database_name = options.delete(:database) || 'wonkavision'
          hosts = options.delete(:hosts)
          unless hosts
            @connection = create_connection(host, port, options)
          else
            @connection = create_repl_set_connection(hosts, options)
          end
          
          self.database_name = database_name

          if username && password && database
            authenticate_database(username, password)
          end   
          @connection                
        end

        def ensure_indexes
          Aggregation.all.values.each do |aggregation|
            if aggregation.store && aggregation.store.respond_to?(:ensure_indexes)
               aggregation.store.ensure_indexes
             end
          end
        end

        protected

        def authenticate_database(username, password)
          database.authenticate(username, password)
        end

        def create_connection(host, port, options)
          raise "Create Connection must be implmeneted by a subclass"
        end     

        def create_repl_set_connection(hosts, options)
          raise "create_repl_set_connection must be implmeneted by a subclass"
        end 
      end
    end
  end
end
