module Wonkavision
  module Analytics
    module Aggregation
      class Algorithm

        def self.[](algo_name)
          @algorithms ||= {}
          @algorithms[algo_name.to_s]
        end

        def self.[]=(algo_name,algorithm)
          @algorithms ||= {}
          @algorithms[algo_name.to_s] = algorithm
        end

        def self.inherited(algorithm)
          self[algorithm.algorithm_name] = algorithm
        end

        def self.algorithm_name
          name.split("::").pop.underscore.to_sym
        end

        def self.measure_name(base_measure_name, time_window)
          "#{base_measure_name}_#{time_window.num_periods}#{time_window.time_unit.to_s[0..0]}_#{algorithm_name}"
        end

        attr_reader :measure_names, :time_window, :context_time, :options

        def initialize(measure_names, time_window, options = {})
          @measure_names = measure_names
          @time_window = time_window
          @options = options
        end

        def matches?(time, record)
          @time_window.include?(time)
        end

        
        #abstract methods
        def add_record(time, values)
          raise NotImplementedException
        end

        #should calculate the stats and return a hash of
        #derived measures. The measure hash can either return
        #values directly, or return a hash of components
        #
        # {
        #   :a_measure => 1.0,
        #   :another_measure => 2.0
        # }
        #
        # OR
        #
        # {
        #    :a_measure => { :sum => 1.0, :count => 1, :sum2 => 1.0 },
        #    :another_measure => {:sum => 2.0, :count => 1, :sum2 => 2.0 }
        # }
        def calculate
          raise NotImplementedException
        end

      end
    end
  end
end
