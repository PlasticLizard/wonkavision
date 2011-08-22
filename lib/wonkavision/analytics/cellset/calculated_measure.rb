module Wonkavision
  module Analytics
    class CellSet
      class CalculatedMeasure < Measure

        attr_reader :name, :cell, :options, :calculation

        def initialize(name,cell,opts={})
          super(name,{},opts)
          @cell = cell
          @data = {}
          @calculation = options[:calculation]
        end

        def value
          cell.send(:instance_eval, &calculation)
        end

        def empty?
          value.nil? || value == 0
        end

        def aggregate(data)
          #noop
        end

        def serializable_hash(options={})
          super.merge!(:calculated=>true)
        end
        
      end
    end
  end
end
