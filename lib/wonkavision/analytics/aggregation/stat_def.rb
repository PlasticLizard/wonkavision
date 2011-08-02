module Wonkavision
  module Analytics
    module Aggregation
      class StatDef
        include Comparable

        attr_reader :statistics, :algorithm, :windows, :measures
         
        def initialize(statistics, algorithm_name, options = {})
          @statistics = statistics
          @algorithm = Algorithm[algorithm_name]
          raise "No algorithm could be found named #{algorithm_name}" unless @algorithm

          @windows = [options.delete(:windows) || 1].flatten.sort
          @measures = [options.delete(:measures) ||
                      options.delete(:only) ||
                      statistics.aggregation.measures.keys].flatten
          @measures = @measures - [options.delete(:except)].flatten if options[:except]
          @algorithm_options = options
        end

        def time_window_units
          "#{statistics.snapshot.resolution}s".to_sym
        end

        def create_algorithms(snapshot_time)
          @windows.map do |window_size|
            window = TimeWindow.new(snapshot_time,window_size,time_window_units)
            algorithm.new(@measures, window, @algorithm_options)
          end
        end
                
        def <=>(other)
          if windows[-1]
            other.windows[-1] ? windows[-1] <=> other.windows[-1] : 1
          else
            other.windows[-1] ? -1 : 0
          end
        end     

      end
    end
  end
end