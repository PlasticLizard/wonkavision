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
        @measure_names = Set.new

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

      def measure_names
        @measure_names.to_a
      end

      def selected_measures
        @query.selected_measures
      end

      def inspect
        @cells.inspect
      end

      def to_s
        @cells.to_s
      end

      def [](*coordinates)
        coordinates.flatten!
        key = coordinates.map{ |c|c.nil? ? nil : c.to_s }
        @cells[key] || Cell.new(self,key,[],{})
      end

      def length
        @cells.length
      end

      private

      def calculate_totals(include_subtotals=false)
        cells.keys.each do |cell_key|
          measure_data = cells[cell_key].measure_data
          append_to_subtotals(measure_data,cell_key)
          @totals ? @totals.aggregate(measure_data) : @totals = Cell.new(self,
                                                                         [],
                                                                         [],
                                                                         measure_data)


        end
      end

      def append_to_subtotals(measure_data, cell_key)
        dims = []
        axes.each do |axis|
          axis.dimensions.each_with_index do |dimension, idx|
            dims << dimension.name
            sub_key = cell_key[0..dims.length-1]

            append_to_cell(dims.dup, measure_data, sub_key) if
              dims.length < cell_key.length #otherwise the leaf and already in the set

            #For axes > 0, subtotals must be padded with nil for all prior axes members
            if (axis.start_index > 0)
              axis_dims = dims[axis.start_index..axis.start_index + idx]
              axis_sub_key = Array.new(axis.start_index) +
                cell_key[axis.start_index..axis.start_index + idx]

              append_to_cell(axis_dims, measure_data, axis_sub_key)
            end

          end
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
          key << record["dimension_keys"][dim_ordinal].to_s
        end
        key
      end

      def update_cell(dimensions,record)
        cell_key ||= key_for(dimensions,record)
        measure_data = record["measures"]
        @measure_names += measure_data.keys if measure_data
        append_to_cell(dimensions, measure_data, cell_key)
      end

      def append_to_cell(dimensions, measure_data, cell_key)
        cell = cells[cell_key]
        cell ? cell.aggregate(measure_data) : cells[cell_key] = Cell.new(self,
                                                                         cell_key,
                                                                         dimensions,
                                                                         measure_data)
      end

    end
  end
end
