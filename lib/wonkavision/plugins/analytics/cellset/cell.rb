module Wonkavision
  module Analytics
    class CellSet
      class Cell
        attr_reader :key, :measures, :dimensions, :cellset

        def initialize(cellset,key,dims,measure_data)
          @cellset = cellset
          @key = key
          @dimensions = dims

          @measures = HashWithIndifferentAccess.new
          measure_data.each_pair do |measure_name,measure|
            measure_opts = cellset.aggregation.measures[measure_name] || {}
            @measures[measure_name] = Measure.new(measure_name,measure,measure_opts)
          end
        end

        def measure_data
          measure_data = {}
          measures.each_pair do |key,value|
            measure_data[key] = value.data
          end
          measure_data
        end

        def aggregate(measure_data)
          measure_data.each_pair do |measure_name,measure_data|
            measure = @measures[measure_name]
            measure ? measure.aggregate(measure_data) :
              @measures[measure_name] = Measure.new(measure_name,measure)
          end
        end

        def calculated_measures
          cellset.aggregation.calculated_measures
        end

        def [](measure_name)
          unless measures.keys.include?(measure_name.to_s)
            calc = calculated_measures[measure_name]
            measures[measure_name] = calc ? CalculatedMeasure.new(measure_name,self,calc) :
              Measure.new(measure_name,{})
          else
            measures[measure_name]
          end
        end

        def method_missing(method,*args)
          self[method]
        end

        def empty?
          measure_data.blank? || measures.values.detect{ |m| !m.empty? }.nil?
        end

        def to_s
          "<Cell #{@key.inspect}>"
        end

        def inspect
          to_s
        end

        def filters
          unless @filters
            @filters = []
            dimensions.each_with_index do |dim_name, index|
              @filters << MemberFilter.new( dim_name, :value => key[index] )
            end
            @filters += cellset.query.slicer
          end
          @filters
        end
      end
    end
  end
end
