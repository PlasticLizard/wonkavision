require "test_helper"

class StatDefTest < ActiveSupport::TestCase
  context "StatDef" do
    setup do
      @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new("2011-07-03", 3, :days)
      @statistics = stub(:snapshot=>stub(:resolution=>:month))
      @stat_def = Wonkavision::Analytics::Aggregation::StatDef.new(@statistics, :rolling_average,
                                                                        :windows => [10,3],
                                                                        :measures => [:a,:b, :c],
                                                                        :except => [:b],
                                                                        :algorithm => :rolling_average)
    end

    should "initialize from constructor options" do
      assert_equal @statistics, @stat_def.statistics
      assert @stat_def.algorithm.name =~ /RollingAverage/
      assert_equal [3, 10], @stat_def.windows
      assert_equal [:a, :c], @stat_def.measures
    end

    should "deduce time window units from the snapshot resolution" do
      assert_equal :months, @stat_def.time_window_units
    end

    context "create_algorithms" do
      setup do
        @algorithms = @stat_def.send(:create_algorithms, "2011-07-27")
      end
      should "return one instantiated algorithm per time window" do
        assert_equal @algorithms.length, 2
      end
      should "set an appropriately configured time window on each algorithm" do
        assert_equal 3, @algorithms[0].time_window.num_periods
        assert_equal "2011-07-27".to_time, @algorithms[0].time_window.context_time
        assert_equal :months, @algorithms[0].time_window.time_unit

        assert_equal 10, @algorithms[1].time_window.num_periods
        assert_equal "2011-07-27".to_time, @algorithms[1].time_window.context_time
        assert_equal :months, @algorithms[1].time_window.time_unit
      end
      should "set the measure on the algorithm" do
        @algorithms.each do |algo|
          assert_equal [:a, :c], algo.measure_names
        end
      end
    end
   
  end
end
