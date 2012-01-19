require "wonkavision/analytics/persistence/mongo_common"
require "wonkavision/analytics/persistence/store/mongo_store"


begin
  require "mongo"
rescue LoadError => error
  raise "Missing dependency: gem install mongo"
end

module Wonkavision
  module Analytics
    module Persistence
      class Mongo
        extend MongoCommon         

        protected

        def self.create_connection(host, port, options)
          ::Mongo::Connection.new(host, port, options)
        end     

        def self.create_repl_set_connection(hosts, options)
          ::Mongo::ReplSetConnection.new(*hosts.push(options))
        end
      end
    end
  end
end
