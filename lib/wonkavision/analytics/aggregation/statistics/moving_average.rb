module Wonkavision
  module Analytics
    module Aggregation
      class MovingAverage < Statistic

        attr_reader :snapshot_binding

        def initialize(snapshot_binding)
          @snapshot_binding = snapshot_binding
        end

        def snapshot
          @snapshot_binding.snapshot
        end

      end
    end
  end
end