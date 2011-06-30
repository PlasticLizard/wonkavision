module Wonkavision
  module Analytics
    module Persistence
      class EMMongoStore < MongoStore

        def database
          EMMongo.database
        end

        def afind(criteria, options={}, &block)
          collection.afind(criteria,options,&block)
        end
        
        def find(criteria, options={})
          collection.find(criteria,options)
        end

        def find_and_modify(opts)
          collection.find_and_modify(opts)
        end

        def update(selector,update,opts={})
          collection.update(selector,update,opts)
        end

      end
    end
  end
end
