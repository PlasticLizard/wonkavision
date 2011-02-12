require "set"

module Wonkavision
  module Analytics
    class CellSet
      attr_reader :axes, :query

      def initialize(aggregation,query,tuples)
        @axes = []
        @query = query
        dimension_members, @cells = process_tuples(aggregation, query, tuples)

        query.axes.each do |axis_dimensions|
          @axes << Axis.new(axis_dimensions,dimension_members,aggregation)
        end

      end

      def columns; axes[0]; end
      def rows; axes[1]; end
      def pages; axex[2]; end
      def chapters; axes[3]; end
      def sections; axes[4]; end

      def inspect
        @cells.inspect
      end

      def to_s
        @cells.to_s
      end

      def [](*coordinates)
        key = coordinates.map{ |c|c.to_s }
        @cells[key] || Cell.new(self,key,coordinates,{})
      end

      def length
        @cells.length
      end

      private

      def process_tuples(aggregation, query, tuples)
        dims = {}
        cells = {}
        tuples.each do |record|
          next unless query.matches_filter?(aggregation, record)
          append_to_cell( cells, query, record )
          record["dimension_names"].each_with_index do |dim_name,idx|
            dim = dims[dim_name] ||= {}
            dim_key = record["dimension_keys"][idx]
            dim[dim_key] ||= record["dimensions"][dim_name]
          end
        end
        [dims, cells]
      end

      def key_for(dims,record)
        key = []
        dims.each_with_index do |dim_name, idx|
          dim_name = dim_name.to_s
          dim_ordinal = record["dimension_names"].index(dim_name)
          key << record["dimension_keys"][dim_ordinal]
        end
        key
      end

      def append_to_cell(cells, query, record)
        #If a slicer is used for a dimension not on one of the main axes,
        #then we'll have cases where more than one tuple needs to be
        #stuck into a cell. In these cases, we need to aggregate
        #the measure data for that cell on the fly
        cell_dims = query.selected_dimensions
        cell_key = key_for(cell_dims,record)
        measures = record["measures"]

        cell = cells[cell_key]
        cell ? cell.aggregate(measures) : cells[cell_key] = Cell.new(self,
                                                                     cell_key,
                                                                     cell_dims,
                                                                     measures)
      end

      class Axis
        attr_reader :dimensions
        def initialize(dimensions,dimension_members,aggregation)
          @dimensions = []
          dimensions.each do |dim_name|
            definition = aggregation.dimensions[dim_name]
            members = dimension_members[dim_name.to_s]
            @dimensions << Dimension.new(self,dim_name,definition,members)
          end
        end
      end

      class Dimension
        attr_reader :definition,:members,:name
        def initialize(axis,name,definition,members)
          @axis = axis
          @name = name.to_s
          @definition = definition
          @members = members ? members.values.map{ |mem_data| Member.new(self,mem_data)}.sort : []
        end
      end

      class Member
        attr_reader :dimension, :attributes
        def initialize(dimension,member_data)
          @dimension = dimension
          @attributes = member_data
        end
        def caption
          attributes[dimension.definition.caption.to_s]
        end
        def key
          attributes[dimension.definition.key.to_s]
        end
        def sort
          attributes[dimension.definition.sort.to_s]
        end
        def <=>(other)
          sort <=> other.sort
        end
        def to_s
          key.to_s
        end
      end

      class Cell
        attr_reader :key, :measures, :dimensions, :cellset

        def initialize(cellset,key,dims,measure_data)
          @cellset = cellset
          @key = key
          @dimensions = dims
          @measures = HashWithIndifferentAccess.new
          measure_data.each_pair do |measure_name,measure|
            @measures[measure_name] = Measure.new(measure_name,measure)
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

      class Measure
        attr_reader :name, :data
        def initialize(name,data)
          @name = name
          @data = data
        end

        def empty?
          count.nil? || count < 1
        end

        def sum; empty? ? nil : @data["sum"]; end
        def sum2; empty? ? nil : @data["sum2"]; end
        def count; @data["count"]; end

        def mean; empty? ? nil : sum/count; end
        alias :average :mean

        def std_dev
          return Wonkavision::NaN unless count > 1
           Math.sqrt((sum2.to_f - ((sum.to_f * sum.to_f)/count.to_f)) / (count.to_f - 1))
        end

        def aggregate(new_data)
          @data["sum"] = @data["sum"].to_f + new_data["sum"].to_f
          @data["sum2"] = @data["sum2"].to_f + new_data["sum2"].to_f
          @data["count"] = @data["count"].to_i + new_data["count"].to_i
        end

      end

    end
  end
end
