module Wonkavision
  module Analytics
    class CellSet
      class Cell
        attr_reader :key, :measures, :dimensions, :cellset, :measure_data

        def initialize(cellset,key,dims,measure_data)
          @cellset = cellset
          @key = key
          @dimensions = dims
          @measure_data = measure_data

          @measures = HashWithIndifferentAccess.new
          @measure_data.each_pair do |measure_name,measure|
            measure_opts = cellset.aggregation.measures[measure_name] || {}
            @measures[measure_name] = Measure.new(measure_name,measure,measure_opts)
          end
        end

        def aggregate(measure_data)
          measure_data.each_pair do |measure_name,measure_data|
            measure = @measures[measure_name]
            measure ? measure.aggregate(measure_data) :
              @measures[measure_name] = Measure.new(measure_name,measure)
          end
        end

        def method_missing(method,*args)
          measures[method] || Measure.new(method,{})
        end

        def empty?
          measure_data.blank?
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
