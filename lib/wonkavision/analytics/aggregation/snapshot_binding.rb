module Wonkavision
  module Analytics
    module Aggregation
      class SnapshotBinding < AggregationSpec

        attr_reader :aggregation, :snapshot

        def initialize(name, aggregation, snapshot)
          super(name)
          @aggregation = aggregation
          @snapshot = snapshot          
        end

        def purge!(snapshot_key_value)
          filter = MemberFilter.new snapshot_key_dimension.name, :value => snapshot_key_value
          @aggregation.store.delete_aggregations(filter)
        end

        def snapshot_key_dimension
          dimensions[snapshot.key_name] || dimensions.values[0]
        end

      end
    end
  end

end
