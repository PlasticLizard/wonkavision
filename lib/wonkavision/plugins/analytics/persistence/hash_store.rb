module Wonkavision
  module Analytics
    module Persistence
      class HashStore < Store

        attr_reader :storage
        def initialize(facts, storage = HashWithIndifferentAccess.new)
          super(facts)
          @storage = storage
        end

        def aggregations
          @storage[:aggregations] ||= {}
        end

        def[](record_id)
          @storage[record_id]
        end

        protected

        #Fact persistence
        def update_facts_record(record_id, data)
          previous_facts = @storage[record_id]
          current_facts = @storage[record_id] = (previous_facts ||  {}).merge(data)
          [previous_facts, current_facts]
        end

        def insert_facts_record(record_id, data)
          @storage[record_id] = data
        end

        def delete_facts_record(record_id, data)
          @storage.delete(record_id)
        end

        def facts_for(aggregation,filters)
          matches = []
          @storage.each_pair do |record_id,facts|
            next if record_id == :aggregations
            failed = filters.detect do |filter|
              attributes = attributes_for(aggregation,filter,facts)
              data = attributes[filter.attribute_key(aggregation)]
              !filter.matches_value(data)
            end
            matches << facts unless failed
          end
          matches
        end

        def attributes_for(aggregation, filter, facts)
          if filter.dimension?
            dimension = aggregation.dimensions[filter.name]
            dimension.complex? ? facts[dimension.from] : facts
          else
            facts
          end
        end

        #Aggregation persistence
        def fetch_tuples(dimension_names = [], filters = [])
          return aggregations.values if dimension_names.blank?
          tuples = []
          aggregations.each_pair do |agg_key, agg|
            tuples << agg if
              agg_key[:dimension_names] == dimension_names
          end
          tuples
        end

        def update_tuple(data)
          key = aggregation_key(data)
          agg = aggregations[key]
          if agg
            data[:measures].keys.each do |measure_key|
              agg[:measures][measure_key] ||= 0
              agg[:measures][measure_key] += data[:measures][measure_key]
            end
          else
            aggregations[key] = data.dup
          end
        end

      end
    end
  end
end
