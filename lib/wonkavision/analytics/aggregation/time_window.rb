module Wonkavision
  module Analytics
    module Aggregation
      class TimeWindow
        include Comparable
      
        attr_reader :context_time, :num_periods, :time_unit, :start_time, :end_time

        def initialize(context_time, num_periods, time_unit)
          @context_time = context_time.kind_of?(Time) ? context_time : context_time.to_time
          @num_periods = num_periods
          @time_unit = time_unit
          @start_time = @context_time.advance(time_unit => (num_periods-1) * -1)
          @end_time = @context_time.advance(time_unit => 1)
        end  
             
        def include?(candidate_time)
          candidate_time = candidate_time.to_time unless candidate_time.is_a?(Time)
          candidate_time >= start_time && candidate_time < end_time
        end

        def <=>(other)
          raise "Cannot comare TimeWindow to #{other.class}" unless other.is_a?(TimeWindow)
          num_periods <=> other.num_periods          
        end
        
      end
    end
  end
end