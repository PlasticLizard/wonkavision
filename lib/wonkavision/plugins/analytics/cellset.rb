module Wonkavision
  module Analytics
    class CellSet < Array
      attr_reader :axes

      def initialize(aggregation,query,tuples)
        @axes = []
        super(tuples)
      end

    end
  end
end
