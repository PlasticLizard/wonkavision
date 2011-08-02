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
      @agg.snapshot :daily do
        statistics { rolling_average }
      end

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
        filter = :dimensions.snapshot_month.eq("2011-07")
        @agg.store.expects(:delete_aggregations).with(filter)  
        @binding.purge!("2011-07-20")
      end 
    end

    context "#statistics" do
      should "construct and store a statistics object" do
        assert_equal 1, @binding.statistics.length
      end
      should "call a block with the stats" do
        @binding.statistics do |s|
          assert s.kind_of?(Wonkavision::Analytics::Aggregation::Statistics)
        end
      end
      should "instance eval the block against the stats if block has no arity" do
        assert_equal 1,  @binding.statistics[0].stats.length 
      end
      should "subscribe to data calc requests" do
        assert @binding.instance_eval("@listening_for_stats")
      end
    end

    context "#calculate_statistics" do
      setup do
        test_data = File.join $test_dir, "test_data.aggregations"
        @test_data = eval(File.read(test_data))
        @sstore = StatStore.new(@test_data)
        @binding.aggregation.expects(:store).returns(@sstore)
        time = "2011-07-27".to_time
        @binding.expects(:submit_stat_snap).with(time, @test_data[0])
        @binding.expects(:submit_stat_snap).with(time, @test_data[1])
          
      end
      should "submit a stat message with the time, names and keys of each record" do
        @binding.calculate_statistics!("2011-07-27".to_time)
      end
      should "construct an appropriate query" do
        @binding.calculate_statistics!("2011-07-27".to_time)
        assert_equal( {
          "dimensions.snapshot_month.month_key" => "2011-07",
          "snapshot" => :daily
        }, @sstore.query )
      end
    end

    context "#submit_stat_snap" do
      should "construct an appropriate message and publish it" do
        expected = {
          :snapshot_time => "07-01-2011".to_time,
          :dimension_names => ["a","b","c"],
          :dimension_keys => ["1","2","3"]
        }
        @binding.expects(:publish).with(expected)
        @binding.submit_stat_snap("07-01-2011".to_time, {"dimension_names" => ["a","b","c"], "dimension_keys" => ["1","2","3"]})
      end
    end

    context "#accept_event" do
      should "extract snap data and call calculate!" do
        stats = @binding.statistics[0]
        snap_message = {
          "snapshot_time" => "07-01-2011".to_time,
          "dimension_names" => ["a","b","c"],
          "dimension_keys" => ["1","2","3"]
        }
        stats.expects(:calculate!).with("07-01-2011".to_time, ["a","b","c"],["1","2","3"])
        @binding.accept_event(snap_message)
      end
    end

  end
end

