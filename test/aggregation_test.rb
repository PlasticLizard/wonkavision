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

    context "instance methods" do
      setup do
        @instance = @agg[{ :a => :b }]
      end

      context "#add" do
        setup do
          @instance.add({ :c => 1.0, :d => 2.0 })
        end

        should "initialize the value for each measure to the aggregation" do
          assert_equal 1.0, @instance.measures["c"].sum
          assert_equal 2.0, @instance.measures["d"].sum
        end

        should "append the value for each measure to the aggregation" do
          @instance.add({ :c => 1.0, :d => 2.0 })
          assert_equal 2.0, @instance.measures["c"].sum
          assert_equal 4.0, @instance.measures["d"].sum
        end

        should "call update with an action of :add" do
          @instance.expects(:update).with({ :c=>1.0,:d=>2.0}, :add)
          @instance.add({ :c=>1.0,:d=>2.0})
        end

      end

      context "#reject" do
        setup do
          @instance.add({ :c => 1.0, :d=> 2.0 })
          @instance.add({ :c => 3.0, :d=>4.0 })
          @instance.reject({ :c => 1.0, :d => 2.0})
        end

        should "remove the measure values from the aggregation" do
          assert_equal 3.0, @instance.measures["c"].sum
          assert_equal 4.0, @instance.measures["d"].sum
          assert_equal 1, @instance.measures["c"].count
          assert_equal 1, @instance.measures["d"].count
        end

        should "call update with an action of :reject" do
          @instance.expects(:update).with({ :c=>1.0,:d=>2.0},:reject)
          @instance.reject({ :c=>1.0,:d=>2.0})
        end

      end

    end
  end
end
