require "test_helper"
require "test_activity_models"

class TimelineTest < ActiveSupport::TestCase
  context "TestBusinessActivity" do
    should "create the appropriate keys" do
      assert TestBusinessActivity.keys.keys.include?("timeline")
      assert TestBusinessActivity.keys.keys.include?("latest_milestone")
    end
    should "configure milestones from DSL" do
      assert_equal 3, TestBusinessActivity.timeline_milestones.length

      assert_equal :ms1, TestBusinessActivity.timeline_milestones[0].name
      assert_equal "test/evt1", TestBusinessActivity.timeline_milestones[0].events[0]

      assert_equal :ms2, TestBusinessActivity.timeline_milestones[1].name
      assert_equal "test/evt2", TestBusinessActivity.timeline_milestones[1].events[0]

      assert_equal :ms3, TestBusinessActivity.timeline_milestones[2].name
      assert_equal "test/evt3", TestBusinessActivity.timeline_milestones[2].events[0]
      assert_equal "/not_test/evt4", TestBusinessActivity.timeline_milestones[2].events[1]
    end
    should "subscribe to all milestone events" do
      assert Wonkavision.event_coordinator.root_namespace.find_or_create("test/evt1").subscribers.length > 0
      assert Wonkavision.event_coordinator.root_namespace.find_or_create("test/evt2").subscribers.length > 0
      assert Wonkavision.event_coordinator.root_namespace.find_or_create("test/evt3").subscribers.length > 0
      assert Wonkavision.event_coordinator.root_namespace.find_or_create("not_test/evt4").subscribers.length > 0
    end
    should "record appropriate milestone time and milestone upon relevant event being received" do
      event = {"test_id"=>"123","event_time"=>"1/1/2001","another_field"=>"hi there"}
      Wonkavision.event_coordinator.receive_event("test/evt1",event)
      assert activity = TestBusinessActivity.find_by_test_id("123")
      assert_equal "1/1/2001".to_time.utc,activity.timeline["ms1"]
      assert_equal "hi there", activity.another_field
      Wonkavision.event_coordinator.receive_event("test/evt2",event)
      activity = activity.reload
      assert_equal "1/1/2001".to_time.utc,activity.timeline["ms2"]
      Wonkavision.event_coordinator.receive_event("test/evt3",event)
      activity = activity.reload
      assert_equal "1/1/2001".to_time.utc, activity.timeline["ms3"]
      event["event_time"] = "1/1/2010"
      Wonkavision.event_coordinator.receive_event("not_test/evt4",event)
      activity = activity.reload
      # timeline for milestone ms3 already set
      assert_equal "1/1/2001".to_time.utc, activity.timeline["ms3"]
      assert_equal "ms3", activity.latest_milestone
    end
    should "not overwrite latest_milestone when processing an event that occurred prior to the latest milestone event" do
      event = {"test_id"=>"123","event_time"=>"1/1/2001 08:00"}
      Wonkavision.event_coordinator.receive_event("test/evt2",event)
      assert activity = TestBusinessActivity.find_by_test_id("123")
      assert_equal "1/1/2001 08:00".to_time.utc,activity.timeline["ms2"]
      assert_equal "ms2", activity.latest_milestone
      event = {"test_id"=>"123","event_time"=>"1/1/2001 07:00"}
      Wonkavision.event_coordinator.receive_event("test/evt1",event)
      activity = activity.reload
      assert_equal "1/1/2001 07:00".to_time.utc, activity.timeline["ms1"]
      assert_equal "ms2", activity.latest_milestone
    end
  end
end