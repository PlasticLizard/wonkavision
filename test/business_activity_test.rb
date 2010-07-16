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
    should "create the appropriate keys" do
    end
    
  end
end