require "em-synchrony"

module Wonkavision
  module Analytics
    class SplitByAggregation
     
      alias :unsafe_process_aggregations :process_aggregations
      def process_aggregations(dims)
        unless Wonkavision::Analytics::Persistence::EMMongo.safe
          unsafe_process_aggregations(dims)
        else
          multi = EM::Synchrony::Multi.new
          dims.each_with_index do |dimensions, idx|
            multi.add idx, apply_aggregation(dimensions)
          end
          multi.perform
          unless errors = multi.responses[:errback].empty?
            error = prepare_error(errors)
            raise *error
          end
          multi.responses[:callback].map{|cb|cb[1].data}
        end
      end

      def prepare_error(errors)
        error_class = errors[0][1].error[0]
        error_detail = errors.map{|e|e[1].error[1]}.join("; ")
        [error_class, "Not all aggregations could be updated: #{error_detail}"]
      end
     
    end
  end
end
