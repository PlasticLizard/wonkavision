module Wonkavision
  module Analytics
    class ApplyAggregation
      
      class << self
        def process(message)
          new.process_message message
        end
      end

      def process_message(event)
        return false unless
          (aggregation = aggregation_for(event["aggregation"])) &&
          (action = event["action"]) &&
          (measures = event["measures"]) &&
          (dimensions = event["dimensions"])

        raise "The only valid values for 'action' on an aggregation.updated message are 'add' and 'reject', #{action} was encountered. Message: #{event.inspect}" unless ["add", "reject"].include?(action.to_s)

        #Don't bother to continue if the measures are all nil
        if measures.values.detect{|m|m}
          action.to_s == "add" ? aggregation[dimensions].add(measures) :
            aggregation[dimensions].reject(measures)
        end

      end

      def aggregation_for(aggregation_name)
        Wonkavision::Analytics::Aggregation.all[aggregation_name]
      end

    end
  end
end
