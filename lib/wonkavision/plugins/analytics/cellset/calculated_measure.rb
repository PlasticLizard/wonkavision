module Wonkavision
  module Analytics
    class CellSet
      class CalculatedMeasure
        attr_reader :name, :cell, :options
        def initialize(name,cell,opts={})
          @name = name
          @cell = cell
          @options = opts
        end
      end
    end
  end
end
