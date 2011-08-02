require "test_helper"

RollingAverage = Wonkavision::Analytics::Aggregation::RollingAverage


class RollingAverageTest < ActiveSupport::TestCase
  context "RollingSum" do
    setup do
      @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new(Time.now, 2, :days)
      @agg = RollingAverage.new([:a,:b],@time_window)
      @agg.add_record(Time.now, {"a" => 2.0, "b" => 3.0 })
      @agg.add_record(Time.now, {"a" => 3.0, "b" => 4.0 })
    end

    should "return the aggregated sum upon #calculate" do
      assert_equal( {
        "a_2d_average" => 2.5,
        "b_2d_average" => 3.5
      }, @agg.calculate )
    end

  
  end
end


