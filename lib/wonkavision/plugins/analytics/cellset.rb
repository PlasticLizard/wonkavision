require "set"

module Wonkavision
  module Analytics
    class CellSet
      attr_reader :axes, :query, :cells, :totals, :aggregation

      def initialize(aggregation,query,tuples)
        @axes = []
        @query = query
        @aggregation = aggregation
        @cells = {}

        dimension_members = process_tuples(tuples)

        start_index = 0
        query.axes.each do |axis_dimensions|
          @axes << Axis.new(self,axis_dimensions,dimension_members,start_index)
          start_index += axis_dimensions.length
        end

        calculate_totals

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
        key = coordinates.map{ |c|c.nil? ? nil : c.to_s }
        @cells[key] || Cell.new(self,key,[],{})
      end

      def length
        @cells.length
      end

      private

      def calculate_totals
        cells.keys.each do |cell_key|
          measure_data = cells[cell_key].measure_data
          axes.each do |axis|
            axis.append_to_totals(cell_key, measure_data) unless
              cells[cell_key].empty?
          end
          @totals ? @totals.aggregate(measure_data) : @totals = Cell.new(self,
                                                                         [],
                                                                         [],
                                                                         measure_data)
        end
      end

      def process_tuples(tuples)
        dims = {}
        tuples.each do |record|
          next unless query.matches_filter?(aggregation, record)
          update_cell( query.selected_dimensions, record )
          record["dimension_names"].each_with_index do |dim_name,idx|
            dim = dims[dim_name] ||= {}
            dim_key = record["dimension_keys"][idx]
            dim[dim_key] ||= record["dimensions"][dim_name]
          end
        end
        dims
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

      def update_cell(dimensions,record)
        cell_key ||= key_for(dimensions,record)
        measure_data = record["measures"]
        append_to_cell(dimensions, measure_data, cell_key)
      end

      def append_to_cell(dimensions, measure_data, cell_key)
        cell = cells[cell_key]
        cell ? cell.aggregate(measure_data) : cells[cell_key] = Cell.new(self,
                                                                         cell_key,
                                                                         dimensions,
                                                                         measure_data)
      end

      class Axis
        attr_reader :cellset, :dimensions, :start_index, :end_index, :totals
        def initialize(cellset,dimensions,dimension_members,start_index)
          @cellset = cellset
          @totals = {}
          @dimensions = []
          dimensions.each do |dim_name|
            definition = cellset.aggregation.dimensions[dim_name]
            members = dimension_members[dim_name.to_s]
            @dimensions << Dimension.new(self,dim_name,definition,members)
          end
          @start_index= start_index
          @end_index = start_index + @dimensions.length - 1
        end

        def[](*coordinates)
          cell_key = coordinates.map{ |c|c.nil? ? nil : c.to_s}
          totals[cell_key] || Cell.new(self.cellset,cell_key,coordinates,{})
        end

        def dimension_names
          dimensions.map{ |d|d.definition.name}
        end

        def append_to_totals(cell_key, measure_data)
          (start_index..end_index).each do |idx|
            totals_dims = dimension_names.slice(0..start_index-idx)
            totals_key = cell_key.slice(start_index..idx)
            append_to_cell( totals_dims, measure_data, totals_key )
          end
        end

        private
        def append_to_cell(dimensions, measure_data, cell_key)
          cell = totals[cell_key]
          cell ? cell.aggregate(measure_data) : totals[cell_key] = Cell.new(self.cellset,
                                                                            cell_key,
                                                                            dimensions,
                                                                            measure_data)
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

      class Measure
        attr_reader :name, :data, :options, :default_component, :format
        def initialize(name,data,opts={})
          @name = name
          @data = data ? data.dup : {}
          @options = opts
          @default_component = options[:default_component] || options[:default_to] || :count
          @format = options[:format] || nil
        end

        def to_s
          formatted_value
        end

        def inspect
          value
        end

        def formatted_value
          format.blank? ? value.to_s : StringFormatter.format(value, format, options)
        end

        def value
          send(@default_component)
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
