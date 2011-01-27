require "test_helper"

class AggregationSpecTest < ActiveSupport::TestCase
  context "AggregationSpec" do
    setup do
      @aggregation_spec = Wonkavision::Plugins::Aggregation::AggregationSpec.new("MyAggregation")
    end

    should "take its name from the constructor" do
      assert_equal "MyAggregation", @aggregation_spec.name
    end

    context "#dimension" do
      setup do
        @aggregation_spec.dimension :a, :b, :c=>"d"
      end

      should "add a dimension for each provided value" do
        assert_equal 2, @aggregation_spec.dimensions.length
        ["a","b"].each { |dim| assert @aggregation_spec.dimensions.keys.include?(dim)}
      end

      should "store pass the options to each dimension" do
        @aggregation_spec.dimensions.values.each { |dim| assert_equal({:c=>"d"},dim.options)}
      end
    end

    context "#measure" do
      setup do
        @aggregation_spec.measure :c, :d, :e => "f"
      end

      should "add a measure for each provided value" do
        assert_equal 2, @aggregation_spec.measures.length
      end

      should "add the attributes as hash elements" do
        [:c, :d].each { |measure| assert @aggregation_spec.measures[measure]}
      end

      should "store the options to each measure" do
        @aggregation_spec.measures.each_pair { |k,v| assert_equal({ "e" => "f"}, v)}
      end
    end

    context "#aggregate_by" do
      setup do
        @aggregation_spec.aggregate_by :a, :b
        @aggregation_spec.aggregate_by :a, :c
        @aggregation_spec.aggregate_by [:a, :c, :d]
      end

      should "append the list of aggregations to the aggregations collection" do
        assert_equal 3, @aggregation_spec.aggregations.length
      end

      should "append the list of aggregations as a simple array" do
        assert_equal [:a, :b], @aggregation_spec.aggregations[0]
      end

      should "flatten arrays of attributes" do
        assert_equal [:a, :c, :d], @aggregation_spec.aggregations[-1]
      end
    end


  end
end
