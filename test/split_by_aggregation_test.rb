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
      end
      @handler = Wonkavision::Analytics::SplitByAggregation.new
    end

    context "#aggregation_for" do
      should "look up an aggregation for the provided name" do
        assert_equal @agg, @handler.aggregation_for(@agg.name)
      end
    end

    context "#split_dimensions_by_aggregation" do
      setup do
        @entity = {"a" => :a, "b" => :b, "c" => :c, "d" => :d, "e" => :e}
        @split = @handler.split_dimensions_by_aggregation(@agg,@entity)
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
        Wonkavision::Analytics::ApplyAggregation.expects(:process).with({ :hi => "there"})
        @handler.process_aggregations [{ :hi => "there"}]
      end
    end

    context "#process_message" do
      should "return false unless all appropriate metadata is present and valid" do
        assert_equal false, @handler.process_message({"aggregation"=>"ack",
                                                    "action"=>"add","data"=>{}})

        assert_equal false, @handler.process_message( { "aggregation"=>@agg.name,
                                                     "action"=>"add"})

        assert_equal false, @handler.process_message( { "aggregation"=>@agg.name,
                                                     "data"=>{}})
      end
      context "with a valid message" do
        setup do
          @message = {
            "aggregation" => @agg.name,
            "action" => "add",
            "data" => {
              "a" => :a, "b" => :b, "c" => :c,
              "d" => 1.0, "e" => 2.0
            }
          }
        end

        should "prepare a message for each aggregation" do
          assert_equal 2, @handler.process_message(@message).length
        end

        should "submit each message for processing" do
          Wonkavision::Analytics::ApplyAggregation.expects(:process).times(2)
          @handler.process_message(@message)
        end

        should "not submit messages if the filter doesn't match" do
          @agg.filter { |m|m["a"] != :a}
          assert_equal 0, @handler.process_message(@message).length
        end

        should "copy the measures once for each aggregation" do
          results =  @handler.process_message(@message)
          results.each do |result|
            assert_equal "add", result["action"]
            assert_equal @agg.name, result["aggregation"]
            assert_equal( { "d" => 1.0, "e" => 2.0, "count" => 1} , result["measures"] )
          end
        end

        should "key each message with a unique aggregation" do
          results = @handler.process_message(@message)
          results[0][:dimensions] = { "a" => :a, "b" => :b}
          results[1][:dimensions] = { "a" => :a, "b" => :b, "c" => :c}
        end

      end    

    end
  end

end
