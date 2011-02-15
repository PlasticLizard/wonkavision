module Wonkavision
  module Analytics
    class CellSet
      class Axis
        attr_reader :cellset, :dimensions, :start_index, :end_index, :members
        def initialize(cellset,dimensions,dimension_members,start_index)
          @cellset = cellset
          @members = HashWithIndifferentAccess.new
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

          members[cell_key] ||  MemberInfo.new(self,cell_key,coordinates,{})
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
          member_info = members[cell_key]
          member_info ? member_info.totals.aggregate(measure_data) :
            members[cell_key] = MemberInfo.new(self,
                                               cell_key,
                                               dimensions,
                                               measure_data)
        end



        class MemberInfo

          attr_reader :axis,:totals, :key
          def initialize(axis,cell_key,dimensions,measure_data)
            @axis = axis
            @key = cell_key
            @totals = CellSet::Cell.new(axis.cellset,cell_key,dimensions,measure_data)
          end

          def descendent_count(include_empty=false)
            return descendent_keys.length if include_empty
            @descendent_count ||= descendent_keys.reject{ |k| axis.members[k].empty? }.length
          end

          def descendent_keys
            @descendent_keys ||= axis.members.keys.select do |k|
              k.length > key.length && k[0..key.length-1] == key
            end
          end

          def empty?
            totals.empty?
          end

        end
      end

    end
  end
end
