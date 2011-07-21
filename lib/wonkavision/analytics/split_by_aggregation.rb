module Wonkavision
  module Analytics
    class SplitByAggregation

      class << self
        def process(aggregation, action, facts, snapshot = nil)
          new(aggregation, action, snapshot).process facts
        end
      end

      def initialize(aggregation, action, snapshot = nil)
        @aggregation = aggregation
        @action = action
        @snapshot = snapshot
      end

      def process(facts)
        return false unless
          @aggregation && @action && facts

        return [] unless @aggregation.matches facts

        facts["count"] ||= 1 #default fact count measure
        @measures = self.measures.keys.inject({}) do |measures,measure|
          measures[measure] = facts[measure.to_s]
          measures
        end

        #Don't bother to continue if the measures are all nil
        return false unless @measures.values.detect{|m|m}
        dims = split_dimensions_by_aggregation(facts).compact
        process_aggregations dims
      end

      def process_aggregations(dims)
        dims.map do |dimensions| 
          apply_aggregation dimensions
        end
      end

      def apply_aggregation(dimensions)
        @action.to_s == "add" ? @aggregation[dimensions, snapshot].add(@measures, snapshot) :
            @aggregation[dimensions, snapshot].reject(@measures, snapshot)
      end

      def aggregations
        return @aggregation.aggregations unless snapshot
        @aggregation.aggregations.map do |agg|
          agg + snapshot.dimensions.keys.map(&:to_sym)
        end
      end

      def snapshot
        @aggregation.snapshots[@snapshot.name] if @snapshot
      end

      def dimensions
        snapshot ? @aggregation.dimensions.merge(snapshot.dimensions) : 
                   @aggregation.dimensions
      end

      def measures
        snapshot ? @aggregation.measures.merge(snapshot.measures) :
                   @aggregation.measures
      end

      def split_dimensions_by_aggregation(facts)
        dimensions = self.dimensions
        self.aggregations.inject([]) do |aggs,aggregate_by|
          aggs << aggregate_by.inject({}) do |dims,dimension_name|
            dimension = dimensions[dimension_name]

            raise "You specified an aggregation containing a dimension that is not defined: #{dimension_name}" unless dimension

            dims[dimension_name.to_s] = dimension.extract(facts)
            dims
          end
          aggs
        end
      end
    end
  end
end
