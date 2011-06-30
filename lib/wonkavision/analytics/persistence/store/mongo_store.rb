module Wonkavision
  module Analytics
    module Persistence
      class MongoStore < Store
        include MongoStoreCommon

        def database
          Mongo.database
        end

      end
    end
  end
end
