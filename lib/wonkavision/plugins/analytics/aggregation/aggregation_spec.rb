module Wonkavision
  module Plugins
    module Aggregation
      class AggregationSpec

        attr_reader :name, :attributes, :measures, :aggregations

        def initialize(name)
          @name = name
          @attributes = HashWithIndifferentAccess.new
          @measures = HashWithIndifferentAccess.new
          @aggregations = []
          @dimensions = Set.new
        end

        def dimension(name, options={}, &block)
          @dimensions << Dimension.new(name,options,&block)
        end

        def dimensions(*dimension_names)
          options = dimension_names.extract_options! || {}
          options.flatten.each { |dim| dimension(dim,options) }
        end

        def attribute(*attribute_list)
          options = attribute_list.extract_options! || {}
          attribute_list.flatten.each { |att| self.attributes[att] = options  }
        end

        def measure(*measure_list)
          options = measure_list.extract_options! || {}
          measure_list.flatten.each { |m| self.measures[m] = options }
        end

        def aggregate_by(*aggregation_list)
          self.aggregations << aggregation_list.flatten
        end

      end
    end
  end

end
