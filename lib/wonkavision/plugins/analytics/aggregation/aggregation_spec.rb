module Wonkavision
  module Plugins
    module Aggregation
      class AggregationSpec

        attr_reader :name, :dimensions, :measures, :calculated_measures, :aggregations, :filter

        def initialize(name)
          @name = name
          #count is the default measure of an aggregation
          @measures = HashWithIndifferentAccess.new(:count => {})
          @calculated_measures = HashWithIndifferentAccess.new
          @aggregations = []
          @dimensions = HashWithIndifferentAccess.new
        end

        def dimension(*dimension_names,&block)
          options = dimension_names.extract_options! || {}
          dimension_names.flatten.each do |dim|
            @dimensions[dim] = Dimension.new(dim,options,&block)
          end
        end

        def measure(*measure_list)
          options = measure_list.extract_options! || {}
          measure_list.flatten.each { |m| self.measures[m] = options }
        end

        def average(*measure_list)
          measure_list.add_options! :default_component=>:average
          measure(*measure_list)
        end
        alias :mean :average

        def count(*measure_list)
          measure_list.add_options! :default_component=>:count
          measure(*measure_list)
        end

        def sum(*measure_list)
          measure_list.add_options! :default_component=>:sum
          measure(*measure_list)
        end

        def calc(measure_name,options={},&block)
          options[:calculation] = block
          calculated_measures[measure_name] = options
        end
        alias calculate calc

        def aggregate_by(*aggregation_list)
          self.aggregations << aggregation_list.flatten
        end

        def aggregate_all_combinations
          dimension_names = dimensions.keys
          (1..dimension_names.length).each do |combination_size|
            dimension_names.combination(combination_size).each { |combo| aggregate_by *combo}
          end
        end
        alias aggregate_by_all aggregate_all_combinations

        def filter(&block)
          return @filter unless block
          @filter = block
        end

        def matches(message)
          return true unless filter
          filter.arity == 0 ? filter.call : filter.call(message)
        end

      end
    end
  end

end
