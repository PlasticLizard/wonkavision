module Wonkavision
  module Analytics
    module Persistence
      class HashStore < Store

        attr_reader :storage
        def initialize(facts, storage = HashWithIndifferentAccess.new)
          super(facts)
          @storage = storage
        end

        def update_facts(data)
          record_id = assert_record_id(data)
          previous_facts = @storage[record_id]
          current_facts = @storage[record_id] = (previous_facts ||  {}).merge(data)
          [previous_facts, current_facts]
        end

        def add_facts(data)
          record_id = assert_record_id(data)
          @storage[record_id] = data
        end

        def remove_facts(data)
          record_id = assert_record_id(data)
          @storage.delete(record_id)
        end

      end
    end
  end
end
