require "test_helper"

class EventHandlerTest < ActiveSupport::TestCase
  context "Classes including Wonkavision::EventHandler" do
    should "handle configured events with a specified block" do
      TestEventHandler.reset
      event = {"a"=>1}
      Wonkavision.event_coordinator.receive_event("vermicious/knid",event)
      assert_equal event, TestEventHandler.knids[0][0]
      assert_equal "vermicious/knid", TestEventHandler.knids[0][1]
    end

    should "invoke any configured message maps" do
      event = {"test_id"=>"123","event_time"=>"1/1/2001","another_field"=>"hi there"}
      Wonkavision.event_coordinator.receive_event("not_test/evt4",event)
      activity = TestBusinessActivity.find_by_test_id("123")
      # timeline for milestone ms3 already set
      assert_equal "1/1/2001".to_time.utc, activity.timeline["ms3"]
      assert_equal "ms3", activity.latest_milestone
      assert_equal "'hi there' WAS SERVED!! OH YEAH!! IN-YOUR-FACE!!",activity.modified_another_field
    end

    should "handle subscriptions to the configured namespace" do
      TestEventHandler.reset
      Wonkavision.event_coordinator.receive_event("vermicious/hose",1)
      Wonkavision.event_coordinator.receive_event("vermicious/dog",2)
      Wonkavision.event_coordinator.receive_event("vermiciouser/knid",3)
      puts TestEventHandler.knids.inspect
      assert_equal 2, TestEventHandler.knids.length
      assert_equal 1, TestEventHandler.knids[0][0]
      assert_equal 2, TestEventHandler.knids[1][0]
    end

    should "handle subscriptions to the root namespace" do
      TestEventHandler.reset
      Wonkavision.event_coordinator.receive_event("a/b/c",1)
      Wonkavision.event_coordinator.receive_event("a/b",2)
      Wonkavision.event_coordinator.receive_event("x/y/x",3)
      assert_equal 3, TestEventHandler.knids.length
      assert_equal 1, TestEventHandler.knids[0][0]
      assert_equal 2, TestEventHandler.knids[1][0]
      assert_equal 3, TestEventHandler.knids[2][0]

    end

    should "only notify once per namespace, even if multiple events are matched in a given namespace" do
      TestEventHandler.reset

      Wonkavision.event_coordinator.map do |events|
        events.namespace :vermicious do |v|
          v.event :composite, 'oompa','loompa'
        end
      end

      Wonkavision.event_coordinator.receive_event("vermicious/oompa",1);
      assert_equal 1, TestEventHandler.knids.length
    end

    should "process any defined callbacks" do
      TestEventHandler.reset

      Wonkavision.event_coordinator.receive_event("vermicious/knid",1)
      #3 execs of each kind of callback, one for event subscription, one for namespace sub and global sub
      assert_equal 3 * 2, TestEventHandler.callbacks.length
    end
    
  end

end