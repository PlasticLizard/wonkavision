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
          cell_key = coordinates.flatten.compact.map{ |c|c.nil? ? nil : c.to_s}
          members[cell_key] ||=  MemberInfo.new(self,cell_key)
        end

        def dimension_names
          dimensions.map { |d| d.definition.name }
        end

        def serializable_hash(options = {})
          {
            :dimensions => dimensions.map { |d| d.serializable_hash( options ) }
          }
        end

        private

        class MemberInfo

          attr_reader :axis, :key
          def initialize(axis,cell_key)
            @axis = axis
            @key = cell_key
          end

          def totals
            cell_key = Array.new(axis.start_index) + key
            cell = axis.cellset[cell_key]
          end

          def descendent_count(include_empty=false)
            return descendent_keys.length if include_empty
            @descendent_count ||= descendent_keys.reject{ |k| axis[k].empty? }.length
          end

          def descendent_keys
            cell_key = Array.new(axis.start_index) + key
            @descendent_keys ||= axis.cellset.cells.keys.select do |k|
              k.length > cell_key.length &&
                k.length <= axis.end_index + 1 &&
                k[0..cell_key.length-1] == cell_key
            end
          end

          def empty?
            totals.empty?
          end

          def to_s
            empty?  ? "<MemberInfo #{key.inspect} empty=true>" : "<MemberInfo #{key.inspect} #{totals}>"
          end

          def inspect
            to_s
          end

        end
      end

    end
  end
end
