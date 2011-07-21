require "test_helper"

class SnapshotBindingTest < ActiveSupport::TestCase
  context "SnapshotBinding" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts" end
        include Wonkavision::Analytics::Facts
        record_id :_id
        snapshot :daily, :query => {"a" => "b"} do
          resolution :month
        end
        store :hash_store
      end

      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAgg"; end
        include Wonkavision::Analytics::Aggregation
        store :hash_store
      end
      @agg.aggregates @facts
      @agg.snapshot :daily

      @binding = @agg.snapshots[:daily]
    end

    should "expose the aggregation" do
      assert_equal @binding.aggregation, @agg
    end

    should "expose the underlying snapshot" do
      assert_equal @binding.snapshot, @facts.snapshots[:daily]
    end

    context "#purge!" do
      should "call delete on the store with an appropriate filter" do
        filter = :dimensions.snapshot_month.eq("2011-07-20")
        @agg.store.expects(:delete_aggregations).with(filter)  
        @binding.purge!("2011-07-20")
      end 
    end


  
  end
end

class DummyStore
  
  
end