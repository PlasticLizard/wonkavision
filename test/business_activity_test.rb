require "test_helper"
require "test_activity_models"

class BusinessActivityTest < ActiveSupport::TestCase
  context "TestBusinessActivity" do
    should "configure namespace from DSL" do
      assert_equal :test, TestBusinessActivity.event_namespace
    end
    should "configure correlation identifiers from DSL" do
      assert_equal({:event=>:test_id, :model=>:test_id}, TestBusinessActivity.correlate_by)
    end
    should "register activity with global registry" do
      assert_equal 1, Wonkavision::Plugins::BusinessActivity.all.length
      assert_equal TestBusinessActivity, Wonkavision::Plugins::BusinessActivity.all[0]
    end

    should "register correlation ids with each activity" do
      ids =  Wonkavision::Plugins::BusinessActivity.all[0].correlation_ids
      assert_equal 1, ids.length
      assert_equal :test_id, ids[0][:event]
    end

    should "use per binding correlation ids when specified" do
      event = {"alt_event_id"=>"123","another_field"=>"hi there"}
      Wonkavision.event_coordinator.receive_event("test/evt5",event)
      assert activity = TestBusinessActivity.find_by_alt_model_id("123")
      assert_equal "hi there", activity.another_field
    end
    
  end
end