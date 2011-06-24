require "test_helper"

class ApplyAggregationTest < ActiveSupport::TestCase
  context "ApplyAggregation" do
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
      @handler = Wonkavision::Analytics::ApplyAggregation.new
    end

    should "initialize with the appropriate namespace" do
      assert_equal Wonkavision.join("wv", "analytics"), @handler.class.event_namespace
    end

    context "#aggregation_for" do
      should "look up an aggregation for the provided name" do
        assert_equal @agg, @handler.aggregation_for(@agg.name)
      end
    end

    context "#process_event" do
      should "return false unless all appropriate metadata is present and valid" do
        assert_equal false, @handler.process_event({"aggregation"=>"ack",
                                                     "action"=>"add","measures"=>{},
                                                     "dimensions"=>{}})

        assert_equal false, @handler.process_event( { "aggregation"=>@agg.name,
                                                      "action"=>"add","measures"=>{}})

        assert_equal false, @handler.process_event( { "aggregation"=>@agg.name,
                                                      "measures"=>{},"dimensions"=>{}})
      end

      context "with a valid message" do
        setup do
          @message = {
            "aggregation" => @agg.name,
            "action" => "add",
            "dimensions" => { "a" => { "a" => :a }, "b" =>{ "b" => :b}, "c" => { "c" =>  :c } },
            "measures" =>{ "d" => 1.0, "e" => 2.0 }
          }

        end

        should "instantiate a new aggregation with the dimensions in the message" do
          aggregator = @agg.new(@message["dimensions"])
          @agg.expects(:new).with(@message["dimensions"]).returns(aggregator)
          @handler.process_event(@message)
        end

        should "add measures if the action is add" do
          @agg.any_instance.expects(:add).with(@message["measures"])
          @handler.process_event(@message)
        end
        should "reject measures if the action is reject" do
          @message["action"] = "reject"
          @agg.any_instance.expects(:reject).with(@message["measures"])
          @handler.process_event(@message)
        end
        should "raise an error if the action is anything other than add or reject" do
          @message["action"] = "whateva"
          assert_raise(RuntimeError) { @handler.process_event(@message) }
        end
        should "do nothing if measures is empty" do
          @message["measures"] = { "d" => nil, "e" => nil}
          @agg.any_instance.expects(:add).never
          @handler.process_event(@message)
        end


      end

    end


    context "will listen for aggregation updated messages" do
      should "respond to aggregation updated messages" do
        Wonkavision::Analytics::ApplyAggregation.any_instance.expects(:process_event)
        Wonkavision.event_coordinator.receive_event("wv/analytics/aggregation/updated",{ :a=>:b})
      end
    end

  end

end
