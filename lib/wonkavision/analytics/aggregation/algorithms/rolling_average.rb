module Wonkavision
  module Analytics
    module Aggregation
      class RollingAverage < Algorithm
        include MovingAggregation

        def self.algorithm_name; :average; end
                  
        def calculate
          measure_names.inject({}) do |accum, measure_name|
            name = self.class.measure_name(measure_name, time_window.num_periods, time_window.time_unit) 
            num = measures[measure_name][:sum].to_f
            denom = measures[measure_name][:count].to_f
            accum[name] = denom > 0 ? num / denom : 0.0
            accum
          end
        end
       
      end
    end
  end
end