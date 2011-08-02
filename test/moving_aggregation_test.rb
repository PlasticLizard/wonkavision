require "test_helper"

MovingAggregation = Wonkavision::Analytics::Aggregation::MovingAggregation

class DummyAggregation < Wonkavision::Analytics::Aggregation::Algorithm
  include MovingAggregation
end

class MovingAggregationTest < ActiveSupport::TestCase
  context "Algorithm" do
    setup do
      @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new(Time.now, 2, :days)
      @agg = DummyAggregation.new([:a,:b],@time_window)
    end

    should "initialize from the constructor" do
      assert_equal( {
        :a => { :count => 0, :sum => 0 },
        :b => { :count => 0, :sum => 0 }
      }, @agg.measures )
    end

    context "add_record" do
      should "increment the count and sum" do
        @agg.add_record(Time.now, {"a" => 2.0, "b" => 4.0 })
        assert_equal( {
          :a => { :count => 1, :sum => 2.0 },
          :b => { :count => 1, :sum => 4.0 }
        }, @agg.measures)

        @agg.add_record(Time.now, {"a" => 3.0, "b" => 5.0 })
        assert_equal( {
          :a => { :count => 2, :sum => 5.0 },
          :b => { :count => 2, :sum => 9.0 }
        }, @agg.measures )
      end
    end    
  end
end


