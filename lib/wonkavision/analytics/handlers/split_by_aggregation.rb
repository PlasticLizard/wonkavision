module Wonkavision
  module Analytics
    class SplitByAggregation

      class << self
        def process(message)
          new.process_message message
        end
      end

      def process_message(event)
        return false unless
          (aggregation = aggregation_for(event["aggregation"])) &&
          (action = event["action"]) &&
          (entity = event["data"])

        return [] unless aggregation.matches entity

        entity["count"] ||= 1 #default fact count measure
        measures = aggregation.measures.keys.inject({}) do |measures,measure|
          measures[measure] = entity[measure.to_s]
          measures
        end

        messages = split_dimensions_by_aggregation(aggregation,entity).map do |dimensions|
          {
            "action" => action,
            "aggregation" => aggregation.name,
            "dimensions" => dimensions,
            "measures" => measures
          }
        end
        process_aggregations messages
      end

      def process_aggregations(messages)
        messages = [messages].flatten
        messages.each {  |message| ApplyAggregation.process(message) }
        messages
      end

      def split_dimensions_by_aggregation(aggregation,entity)
        aggregation.aggregations.inject([]) do |aggregations,aggregate_by|
          aggregations << aggregate_by.inject({}) do |dimensions,dimension_name|
            dimension = aggregation.dimensions[dimension_name]

            raise "You specified an aggregation containing a dimension that is not defined: #{dimension_name}" unless dimension

            dimensions[dimension_name.to_s] = dimension.extract(entity)
            dimensions
          end
          aggregations
        end
      end

      def aggregation_for(aggregation_name)
        Wonkavision::Analytics::Aggregation.all[aggregation_name]
      end
    end
  end
end
