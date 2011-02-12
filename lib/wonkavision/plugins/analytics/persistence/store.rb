module Wonkavision
  module Analytics
    module Persistence
      class Store

        def self.[](store_name)
          @stores ||= {}
          @stores[store_name.to_s]
        end

        def self.[]=(store_name,store)
          @stores ||= {}
          @stores[store_name.to_s] = store
        end

        def self.inherited(store)
          store_name = store.name.split("::").pop.underscore
          self[store_name] = store
        end

        attr_reader :owner
        def initialize(owner)
          @owner = owner
        end

        #Facts persistence support
        #
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

        #Aggregations persistence support
        #
        # Takes a Wonkavision::Analytics::Query and returns an array of
        # matching tuples
        def execute_query(query)
          dimension_names = query.all_dimensions? ? [] :
            query.referenced_dimensions.sort{ |a,b| a.to_s <=> b.to_s }

          fetch_tuples(dimension_names, query.filters)

        end

        def update_aggregation(aggregation_data)
          update_tuple(aggregation_data)
        end

        protected

        def assert_record_id(data)
          raise "The storage owner does not implement a 'record_id' method. (#{owner.inspect})" unless owner.respond_to?(:record_id)

          data[owner.record_id.to_s].tap do |id|
            raise "A record_id is required to update the analytics store" unless id
          end
        end

        def aggregation_key(aggregation_data)
          {
            :dimension_keys => aggregation_data[:dimension_keys],
            :dimension_names => aggregation_data[:dimension_names]
          }
        end

        #Abstract methods
        def facts_for(aggregation,*filters)
          raise NotImplementedError
        end

        def update_facts_record(record_id, data)
          raise NotImplementedError
        end

        def insert_facts_record(record_id, data)
          raise NotImplementedError
        end

        def fetch_tuples(dimension_names, filters = [])
          raise NotImplementedError
        end

        def update_tuple(aggregation_data)
          raise NotImplementedError
        end

        def  delete_facts_record(record_id, data)
          raise NotImplementedError
        end

      end
    end
  end
end
