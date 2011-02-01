module Wonkavision
  module Analytics
    module Persistence
      class Store

        attr_reader :facts
        def initialize(facts)
          @facts = facts
        end

        # returns a two element array, the first element
        # containing the prior state of the facts record,
        # the second element containing the current state
        # of the facts record
        def update_facts(data)
          record_id = assert_record_id(data)
          update_facts_record record_id, data
        end

        #returns the current value of the facts record
        def add_facts(data)
          record_id = assert_record_id(data)
          insert_facts_record record_id, data
        end

        #returns the previous value of the facts record
        def remove_facts(data)
          record_id = assert_record_id(data)
          delete_facts_record record_id, data
        end

        protected

        def assert_record_id(data)
          data[facts.record_id.to_s].tap do |id|
            raise "A record_id is required to update the analytics store" unless id
          end
        end

        #Abstract methods
        def update_facts_record(record_id, data)
          raise NotImplementedError
        end

        def insert_facts_record(record_id, data)
          raise NotImplementedError
        end


        def  delete_facts_record(record_id, data)
          raise NotImplementedError
        end

      end
    end
  end
end
