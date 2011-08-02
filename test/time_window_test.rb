require "test_helper"

class TimeWindowTest < ActiveSupport::TestCase
  context "TimeWindow" do
    setup do
      @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new("2011-07-03", 3, :days)
    end

    should "initialize from the constructor" do
      assert_equal "2011-07-03".to_time, @time_window.context_time
      assert_equal 3, @time_window.num_periods
      assert_equal :days, @time_window.time_unit
      assert_equal "2011-07-01".to_time, @time_window.start_time
      assert_equal "2011-07-04".to_time, @time_window.end_time
    end

    should "detect if a date is included" do
      assert @time_window.include?("2011-07-02")
    end

    should "detect if a date is not included" do
      assert !@time_window.include?("2011-07-04")
    end

    should "include the two ends of the range" do
      assert @time_window.include?("2011-07-01")
      assert @time_window.include?("2011-07-03")
    end
   
  end
end
