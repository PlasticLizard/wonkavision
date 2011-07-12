module Wonkavision
  module Analytics
    module Persistence
      class EMMongoStore < Store
        include MongoStoreCommon

        def database
          EMMongo.database
        end

        def safe
          EMMongo.safe
        end

        def find(criteria, options={})
          collection.find(criteria,options).to_a
        end

        def find_and_modify(opts)
          collection.find_and_modify(opts)
        end

        def update(selector,update,opts={})
          collection.safe_update(selector,update,opts)
        end

      end
    end
  end
end
