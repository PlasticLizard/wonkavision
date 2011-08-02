module Wonkavision
  module Analytics
    module Persistence
      class Store

        def self.[](store_name)
          @stores ||= {}
          if store_name.to_s == "default"
            @stores["default"] ||= Wonkavision::Analytics.default_store          
          else
            @stores[store_name.to_s]
          end
        end

        def self.[]=(store_name,store)
          @stores ||= {}
          @stores[store_name.to_s] = store
        end

        def self.inherited(store)
          self[store.store_name] = store
        end

        def self.store_name
          name.split("::").pop.underscore
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
        def execute_query(query, &block)
          dimension_names = query.all_dimensions? ? [] :
            query.referenced_dimensions.dup.
              concat(Wonkavision::Analytics.context.global_filters.
              select{ |f| f.dimension?}.map{ |dim_filter| dim_filter.name.to_s }).uniq.
              sort{ |a,b| a.to_s <=> b.to_s }

          filters = (query.filters + Wonkavision::Analytics.context.global_filters).compact.uniq

          fetch_tuples(dimension_names, filters, &block)
        end

        def update_aggregation(aggregation_data, incremental = true)
          update_tuple(aggregation_data, incremental)
        end

        def facts_for(aggregation,filters,options={})
          filters = (filters + Wonkavision::Analytics.context.global_filters).compact.uniq
          fetch_facts(aggregation,filters,options)
        end

        #abstract
        def purge!(criteria=nil)
          raise NotImplementedError
        end

        def where(query)
          raise NotImplementedError
        end

        def each(query, &block)
          raise NotImplementedError
        end

        def delete_aggregations(*filters)
          raise NotImplementedError
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
        def fetch_facts(aggregation,filters,options)
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
