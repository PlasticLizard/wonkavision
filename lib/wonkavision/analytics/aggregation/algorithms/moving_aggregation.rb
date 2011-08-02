module Wonkavision
  module Analytics
    module Aggregation
      module MovingAggregation
        
        attr_reader :measures
        
        def initialize(*args)
          super
          @measures = {}
          measure_names.each do |name|
            @measures[name] = {
              :count => 0,
              :sum => 0
            } 
          end
        end

        def add_record(time, record_data)
          measure_names.each do |measure_name|
            m = @measures[measure_name]
            m[:count] += 1
            m[:sum] += record_data[measure_name.to_s]
          end
        end
       
      end
    end
  end
end