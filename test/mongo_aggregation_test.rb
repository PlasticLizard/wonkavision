require "test_helper"

class MongoAggregationTest < ActiveSupport::TestCase
  context "MongoAggregation" do
    setup do
      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyMongoAggregation"; end
        include Wonkavision::MongoAggregation
        attribute :a, :b, :c
      end
    end

    should "register itself with the module" do
      assert_equal @agg, Wonkavision::Aggregation.all[@agg.name]
    end

    context "class methods" do
      should "provide a collection name based off of the aggregation name" do
        assert_equal "wv.my_mongo_aggregation.aggregations", @agg.data_collection_name
      end

      should "return a collection based on the data_collection_name" do
        assert_equal "wv.my_mongo_aggregation.aggregations", @agg.data_collection.name
      end

    end


    context "instance methods" do
      setup do
        @instance = @agg[{ :a => :b }]
      end

      context "#add" do
        setup do
          @instance.add({ :c => 1.0, :d => 2.0 })
        end

        should "create a record in the database for the aggregation" do
          assert_equal 1, @agg.data_collection.find(:attributes => { :a=>:b } ).to_a.length
        end

        context "when succesful" do
          setup do
            @measures = @agg.data_collection.find(:attributes=>{ :a=>:b}).to_a[0]["measures"]
          end

          should "initialize the value for each measure to the aggregation" do
            assert_equal 1.0, @measures["c"]["sum"]
            assert_equal 2.0, @measures["d"]["sum"]
          end

          should "append the value for each measure to the aggregation" do
            @instance.add({ :c => 1.0, :d => 2.0 })
            @measures = @agg.data_collection.find(:attributes=>{ :a=>:b}).to_a[0]["measures"]
            assert_equal 2.0, @measures["c"]["sum"]
            assert_equal 4.0, @measures["d"]["sum"]
          end
        end

      end

      context "#reject" do
        setup do
          @instance.add({ :c => 1.0, :d=> 2.0 })
          @instance.add({ :c => 3.0, :d=>4.0 })
          @instance.reject({ :c => 1.0, :d => 2.0})
        end

        should "remove the measure values from the aggregation" do
#          assert_equal 3.0, @instance.measures["c"].sum
#          assert_equal 4.0, @instance.measures["d"].sum
#          assert_equal 1, @instance.measures["c"].count
#          assert_equal 1, @instance.measures["d"].count
        end

      end

    end
  end
end
