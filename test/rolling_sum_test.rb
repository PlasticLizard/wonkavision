require "test_helper"

RollingSum = Wonkavision::Analytics::Aggregation::RollingSum


class RollingSumTest < ActiveSupport::TestCase
  context "RollingSum" do
    setup do
      @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new(Time.now, 2, :days)
      @agg = RollingSum.new([:a,:b],@time_window)
      @agg.add_record(Time.now, {"a" => 2.0, "b" => 3.0 })
      @agg.add_record(Time.now, {"a" => 3.0, "b" => 4.0 })
    end

    should "return the aggregated sum upon #calculate" do
      assert_equal( {
        "a_2d_sum" => 5.0,
        "b_2d_sum" => 7.0
      }, @agg.calculate )
    end

  
  end
end


