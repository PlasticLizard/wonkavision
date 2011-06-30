require "wonkavision/analytics/persistence/mongo_common"
require "wonkavision/analytics/persistence/store/em_mongo_store"

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

        protected

        def self.create_connection(host, port, options = {})
          timeout = options.delete(:timeout)
          EM::Mongo::Connection.new(host, port, timeout, options)
        end     

      end
    end
  end
end