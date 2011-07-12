require "wonkavision/analytics/persistence/mongo_common"
require "wonkavision/analytics/persistence/store/em_mongo_store"
require "wonkavision/analytics/em_split_by_aggregation"

begin
  require "em-mongo"
rescue LoadError => error
  raise "Missing dependency: gem install em-mongo"
end

begin
  require "em-synchrony"
  require "em-synchrony/em-mongo"
rescue LoadError => error
  raise "Missing dependency: gem install em-synchrony"
end

module Wonkavision
  module Analytics
    module Persistence
      class EMMongo
        extend MongoCommon
        
        def self.connection=(connection)
          @connection=connection
        end      

        #em-mongo does not internally pool connections,
        #so self.connection might be a em-syncrhony
        #collection pool.
        #For that reason, we are not caching the database
        #in the adapter as, unlike with the mongo-ruby driver,
        #it will not nessarily be associated with the 
        #current connection        
        def self.database
          database_name ? connection.db(database_name) : nil
        end   

        protected

        def self.create_connection(host, port, options = {})
          timeout = options.delete(:timeout)
          EM::Mongo::Connection.new(host, port, timeout, options)
        end     

      end
    end
  end
end