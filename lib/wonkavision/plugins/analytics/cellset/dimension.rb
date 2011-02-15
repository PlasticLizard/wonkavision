module Wonkavision
  module Analytics
    class CellSet
      class Dimension
        attr_reader :definition,:members,:name
        def initialize(axis,name,definition,members)
          @axis = axis
          @name = name.to_s
          @definition = definition
          @members = members ? members.values.map{ |mem_data| Member.new(self,mem_data)}.sort : []
        end
      end

    end
  end
end
