module Wonkavision
  module Plugins
    module Aggregation
      class AggregationSpec

        attr_reader :name, :dimensions, :measures, :aggregations, :filter

        def initialize(name)
          @name = name
          @measures = HashWithIndifferentAccess.new
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

        def aggregate_by(*aggregation_list)
          self.aggregations << aggregation_list.flatten
        end

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
