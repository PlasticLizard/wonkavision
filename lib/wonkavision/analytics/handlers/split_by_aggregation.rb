module Wonkavision
  module Analytics
    class SplitByAggregation
      include Wonkavision::EventHandler

      event_namespace Wonkavision.join('wv', 'analytics')

      handle Wonkavision.join('entity', 'updated') do
        process_event(event_context.data)
      end

      def process_event(event)
        return false unless
          (aggregation = aggregation_for(event["aggregation"])) &&
          (action = event["action"]) &&
          (entity = event["entity"])

        measures = aggregation.measures.keys.inject({}) do |measures,measure|
          measures[measure] = entity[measure.to_s]
          measures
        end

        messages = split_attributes_by_aggregation(aggregation,entity).map do |attributes|
          {
            :action => action,
            :aggregation => aggregation.name,
            :attributes => attributes,
            :measures => measures
          }
        end

        process_aggregations messages
      end

      def process_aggregations(messages)
        messages = [messages].flatten
        event_path = self.class.event_path( Wonkavision.join('aggregation', 'updated') )
        messages.each {  |message| submit(event_path, message) }
        messages
      end

      def split_attributes_by_aggregation(aggregation,entity)
        aggregation.aggregations.inject([]) do |aggregations,aggregate_by|
          aggregations << aggregate_by.inject({}) do |attributes,attribute|
            attributes[attribute.to_s] = entity[attribute.to_s]
            attributes
          end
          aggregations
        end
      end

      def aggregation_for(aggregation_name)
        Wonkavision::Aggregation.all[aggregation_name]
      end

    end
  end
end
