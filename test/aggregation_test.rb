require "test_helper"

class AggregationTest < ActiveSupport::TestCase
  context "Aggregation" do
    setup do
      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAggregation" end
        include Wonkavision::Aggregation
        attribute :a, :b, :c
      end
    end

    should "configure a specification" do
      assert_not_nil @agg.aggregation_spec
    end

    should "set the name of the aggregation to the name of the class" do
      assert_equal @agg.name, @agg.aggregation_spec.name
    end

    should "proxy relevant calls to the specification" do
      assert_equal @agg.attributes, @agg.aggregation_spec.attributes
      assert_equal 3, @agg.attributes.length
    end

    should "register itself with the module" do
      assert_equal @agg, Wonkavision::Aggregation.all[@agg.name]
    end

    should "manage a list of cached instances keyed by attribute hashes" do
      instance = @agg[{ :a => :b}]
      assert_not_nil instance
      assert_equal instance, @agg[{ :a => :b}]
      assert_not_equal instance, @agg[{ :a => :c}]
      assert_not_equal instance, @agg[{ :a => :b, :c => :d}]
    end

    should "store the attributes list with the instance" do
      instance = @agg[{ :a=> :b}]
      assert_equal( { :a => :b}, instance.attributes )
    end

  end
end
