module Wonkavision
  module Analytics
    class ApplyAggregation
      include Wonkavision::EventHandler

      event_namespace Wonkavision.join('wv', 'analytics')

      handle Wonkavision.join('aggregation', 'updated') do
        process_event(event_context.data)
      end

      def process_event(event)
        return false unless
          (aggregation = aggregation_for(event["aggregation"])) &&
          (action = event["action"]) &&
          (measures = event["measures"]) &&
          (dimensions = event["dimensions"])

        raise "The only valid values for 'action' on an aggregation.updated message are 'add' and 'reject', #{action} was encountered. Message: #{event.inspect}" unless ["add", "reject"].include?(action.to_s)

        #Don't bother to continue if the measures are all nil
        if measures.values.detect{|m|m}
          measures["count"] ||= 1
          action.to_s == "add" ? aggregation[dimensions].add(measures) :
            aggregation[dimensions].reject(measures)
        end

      end

      def aggregation_for(aggregation_name)
        Wonkavision::Aggregation.all[aggregation_name]
      end

    end
  end
end
