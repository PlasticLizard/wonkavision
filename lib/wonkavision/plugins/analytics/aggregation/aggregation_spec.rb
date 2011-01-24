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