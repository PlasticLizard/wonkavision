require "test_helper"

class SplitByAggregationTest < ActiveSupport::TestCase
  context "SplitByAggregation" do
    setup do
      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAggregation" end
        include Wonkavision::Analytics::Aggregation
        dimension :a, :b, :c
        measure :d, :e
        aggregate_by :a, :b
        aggregate_by :a, :b, :c
        store :hash_store
        snapshot :daily do
          measure :f
        end
      end
      @handler = Wonkavision::Analytics::SplitByAggregation.new(@agg, "add")
    end

    context "#split_dimensions_by_aggregation" do
      setup do
        @entity = {"a" => :a, "b" => :b, "c" => :c, "d" => :d, "e" => :e}
        @split = @handler.split_dimensions_by_aggregation(@entity)
      end
      should "create one entry per aggregate_by" do
        assert_equal 2, @split.length
      end
      should "create a hash of key values for each aggregation" do
        assert_equal( { "a" => { "a" => :a}, "b" => { "b"=>:b} }, @split[0] )
        assert_equal( { "a" => { "a" => :a}, "b" => { "b"=>:b} , "c"=>{ "c"=>:c} }, @split[1] )
      end
    end

    context "#process_aggregations" do
      should "call process on each message in the batch" do
        @handler.expects(:apply_aggregation).with(["a","b"])
        @handler.process_aggregations [["a","b"]]
      end
    end

    context "#process" do
      context "with a valid message" do
        setup do
          @message = {
              "a" => :a, "b" => :b, "c" => :c,
              "d" => 1.0, "e" => 2.0
          }
        end

        should "prepare a message for each aggregation" do
          assert_equal 2, @handler.process(@message).length
        end

        should "apply each aggregation" do
          @handler.expects(:apply_aggregation).times(2)
          @handler.process(@message)
        end

        should "not submit messages if the filter doesn't match" do
          @agg.filter { |m|m["a"] != :a}
          assert_equal 0, @handler.process(@message).length
        end

        should "copy the measures once for each aggregation" do
          results =  @handler.process(@message)
          results.each do |result|
            assert_equal( {"measures.count.count"=>1,
                           "measures.count.sum"=>1,
                           "measures.count.sum2"=>1,
                           "measures.d.count"=>1,
                           "measures.d.sum"=>1.0,
                           "measures.d.sum2"=>1.0,
                           "measures.e.count"=>1,
                           "measures.e.sum"=>2.0,
                           "measures.e.sum2"=>4.0} , result[:measures] )
          end
        end

        should "key each message with a unique aggregation" do
          results = @handler.process(@message)
          results[0][:dimensions] = { "a" => :a, "b" => :b}
          results[1][:dimensions] = { "a" => :a, "b" => :b, "c" => :c}
        end

      end    

    end

    context "With a snapshot" do
      setup do
        @snap = Wonkavision::Analytics::Snapshot.new(nil, :daily, :event_name=>"")
        @snap_handler = Wonkavision::Analytics::SplitByAggregation.new(@agg, "add", @snap)
      end
      should "include snapshot dims in aggregations" do
        assert_equal [[:a,:b,:snapshot_time],[:a,:b,:c,:snapshot_time]],
                      @snap_handler.aggregations
      end
      should "include snapshot measures in measures" do
        assert_equal ["count","d","e","f"], @snap_handler.measures.keys.sort
      end
      should "return the snapshot from the aggregation" do
        assert @snap_handler.snapshot
      end
      should "return snapshot dimensions" do
        assert @snap_handler.dimensions[:snapshot_time]  
      end
    end
  end

end
