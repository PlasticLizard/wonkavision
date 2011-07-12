module Wonkavision
  module Analytics
    module Persistence
      class MongoStore < Store
        include MongoStoreCommon

        def database
          Mongo.database
        end

        def safe
          Mongo.safe
        end

      end
    end
  end
end
