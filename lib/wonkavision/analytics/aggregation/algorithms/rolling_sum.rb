module Wonkavision
  module Analytics
    module Aggregation
      class RollingSum < Algorithm
        include MovingAggregation

        def self.algorithm_name; :sum; end
                  
        def calculate
          measure_names.inject({}) do |accum, measure_name|
            name = self.class.measure_name(measure_name, time_window) 
            accum[name] = @measures[measure_name][:sum]
            accum
          end
        end
       
      end
    end
  end
end