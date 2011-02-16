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
          key = parents << name
          members.reject { |mem| axis[key].empty? }
        end

      end

    end
  end
end
