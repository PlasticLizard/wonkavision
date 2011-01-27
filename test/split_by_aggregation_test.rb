require "test_helper"

class SplitByAggregationTest < ActiveSupport::TestCase
  context "SplitByAggregation" do
    setup do
      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAggregation" end
        include Wonkavision::Aggregation
        dimension :a, :b, :c
        measure :d, :e
        aggregate_by :a, :b
        aggregate_by :a, :b, :c
      end
      @handler = Wonkavision::Analytics::SplitByAggregation.new
    end

    should "initialize with the appropriate namespace" do
      assert_equal Wonkavision.join("wv", "analytics"), @handler.class.event_namespace
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
      should "create a hasn of key values for each aggregation" do
        assert_equal( { "a" => :a, "b" => :b}, @split[0] )
        assert_equal( { "a" => :a, "b" => :b, "c" => :c}, @split[1] )
      end
    end

    context "#process_aggregations" do
      should "call process on each message in the batch" do
        path = Wonkavision.join("wv", "analytics", "aggregation", "updated")
        @handler.expects(:submit).with(path, { :hi => "there"})
        @handler.process_aggregations [{ :hi => "there"}]
      end
    end

    context "#process_event" do
      should "return false unless all appropriate metadata is present and valid" do
        assert_equal false, @handler.process_event({"aggregation"=>"ack",
                                                    "action"=>"add","entity"=>{}})

        assert_equal false, @handler.process_event( { "aggregation"=>@agg.name,
                                                     "action"=>"add"})

        assert_equal false, @handler.process_event( { "aggregation"=>@agg.name,
                                                     "entity"=>{}})
      end
      context "with a valid message" do
        setup do
          @message = {
            "aggregation" => @agg.name,
            "action" => "add",
            "entity" => {
              "a" => :a, "b" => :b, "c" => :c,
              "d" => 1.0, "e" => 2.0
            }
          }
        end
        should "prepare a message for each aggregation" do
          assert_equal 2, @handler.process_event(@message).length
        end
        should "submit each message for processing" do
          @handler.expects(:submit).times(2)
          @handler.process_event(@message)
        end
        should "copy the measures once for each aggregation" do
          results =  @handler.process_event(@message)
          results.each do |result|
            assert_equal "add", result[:action]
            assert_equal @agg.name, result[:aggregation]
            assert_equal( { "d" => 1.0, "e" => 2.0} , result[:measures] )
          end
        end
        should "key each message with a unique aggregation" do
          results = @handler.process_event(@message)
          results[0][:dimensions] = { "a" => :a, "b" => :b}
          results[1][:dimensions] = { "a" => :a, "b" => :b, "c" => :c}
        end

      end
      context "will listen for entity updated messages" do
        should "respond to entity updated messages" do
          Wonkavision::Analytics::SplitByAggregation.any_instance.expects(:process_event)
          Wonkavision.event_coordinator.receive_event("wv/analytics/entity/updated",{ :a=>:b})
        end
      end

    end
  end

end
