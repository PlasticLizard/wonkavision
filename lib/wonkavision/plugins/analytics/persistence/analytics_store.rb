module Wonkavision
  module Analytics
    module Persistence
      class Store

        attr_reader :facts
        def initialize(facts)
          @facts = facts
        end

        def assert_record_id(data)
          data[facts.record_id].tap do |id|
            raise "A record_id is required to update the analytics store" unless id
          end
        end

        # returns a two element array, the first element
        # containing the prior state of the facts record,
        # the second element containing the current state
        # of the facts record
        def update_facts(data)
          raise NotImplementedError
        end

        #returns the current value of the facts record
        def add_facts(data)
          raise NotImplementedError
        end


        #returns the previous value of the facts record
        def  remove_facts(data)
          raise NotImplementedError
        end

      end
    end
  end
end
