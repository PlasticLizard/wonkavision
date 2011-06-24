module Wonkavision
  module Analytics
    class CellSet
      class Dimension
        attr_reader :definition,:members,:name, :axis
        def initialize(axis,name,definition,members)
          @axis = axis
          @name = name.to_s
          @definition = definition
          @members = members ? members.values.map{ |mem_data| Member.new(self,mem_data)}.sort : []
        end

        def non_empty(*parents)
          members.reject { |mem| key = parents.dup << mem.key; axis[key].empty? }
        end

        def position
          axis.dimensions.index(self)
        end

        def next_dimension
          axis.dimensions[position+1]
        end

        def previous_dimension
          axis.dimensions[position-1]
        end

        def root?
          !previous_dimension
        end

        def leaf?
          !next_dimension
        end

      end

    end
  end
end
