require "test_helper"

Algorithm = Wonkavision::Analytics::Aggregation::Algorithm

class AlgorithmTest < ActiveSupport::TestCase
  context "Algorithm" do
    setup do
      @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new(Time.now, 2, :days)
      @algorithm = Algorithm.new([:a,:b],@time_window)
    end

    context "class method" do
      should "maintain a registry of subclasses" do
        assert_equal DummyAlgorithm, Algorithm[:dummy_algorithm]
      end
    
      should "return the name of the algorithm" do
        assert_equal :dummy_algorithm, DummyAlgorithm.algorithm_name
      end

      should "generate a reasonable measure name" do
        assert_equal "my_measure_2d_dummy_algorithm", DummyAlgorithm.measure_name("my_measure", @time_window)
      end
    end


    should "initialize from the constructor" do
      assert @algorithm.measure_names == [:a,:b]
      assert @algorithm.time_window == @time_window
      assert @algorithm.options == {}
    end

    context "matches?" do
      should "should return true when a record matches the time window" do
        assert @algorithm.matches?(Time.now - 1000,[])
      end

      should "should return false when a record is not in the time window" do
        assert !@algorithm.matches?(Time.now + 86400,[])
      end
    end
    
    
  end
end

class DummyAlgorithm < Algorithm
end