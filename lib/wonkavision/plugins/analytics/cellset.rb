module Wonkavision
  module Analytics
    class CellSet < Array
      attr_reader :axes

      def initialize(aggregation,query,tuples)
        @axes = build_axes(aggregation,query,tuples)
        super(tuples)
      end

      private

      def build_axes(agg,query,tuples)

      end

    end
  end
end
