require "test_helper"

class AggregationTest < ActiveSupport::TestCase
  context "Aggregation" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        include Wonkavision::Facts
      end

      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAggregation"; end
        include Wonkavision::Aggregation
        dimension :a, :b, :c

        dimension :complex do
          key :cpx
        end

        measure :d
        store :hash_store
      end
      @agg.aggregates @facts

    end

    should "configure a specification" do
      assert_not_nil @agg.aggregation_spec
    end

    should "set the name of the aggregation to the name of the class" do
      assert_equal @agg.name, @agg.aggregation_spec.name
    end

    should "proxy relevant calls to the specification" do
      assert_equal @agg.dimensions, @agg.aggregation_spec.dimensions
      assert_equal 4, @agg.dimensions.length
    end

    should "create complex dimensions" do
      assert_equal :cpx, @agg.dimensions[:complex].key
    end

    should "register itself with the module" do
      assert_equal @agg, Wonkavision::Aggregation.all[@agg.name]
    end

    should "set the aggregates property" do
      assert_equal @facts, @agg.aggregates
    end

    should "register itself with its associated Facts class" do
      assert_equal 1, @facts.aggregations.length
      assert_equal @agg, @facts.aggregations[0]
    end

    should "set the specified storage" do
      assert @agg.store.kind_of?(Wonkavision::Analytics::Persistence::HashStore)
      assert_equal @agg, @agg.store.owner
    end

    should "manage a list of cached instances keyed by dimension hashes" do
      instance = @agg[{ "a" => { "a"=>:b}}]
      assert_not_nil instance
      assert_equal instance, @agg[{ "a" => { "a"=>:b}}]
      assert_not_equal instance, @agg[{  "a" => { "a"=>:b},  "b" => { "b"=>:c}}]
    end

    should "store the dimension list with the instance" do
      instance = @agg[{ "a" => { "a"=>:b}}]
      assert_equal( { "a" => { "a"=>:b}}, instance.dimensions )
    end

    context "#query" do
      should "create a new query" do
        assert @agg.query(:defer=>true).kind_of?(Wonkavision::Analytics::Query)
      end
      should "apply a provided block to the query" do
        assert_equal [:a], @agg.query(:defer=>true){ select :a }.selected_dimensions
      end
      should "raise an error if the query is invalid" do
        assert_raise(RuntimeError) { @agg.query{ select :a, :on => :rows} }
      end
      should "execute the query against the configured store" do
        @agg.store.expects(:execute_query).returns([])
        @agg.query
      end
      should "return a cellset based on the query results" do
        @agg.store.expects(:execute_query).returns([])
        assert @agg.query.kind_of?(Wonkavision::Analytics::CellSet)
      end
    end

    context "#facts_for" do
      should "pass the request to the underlying Facts class" do
        @facts.expects(:facts_for).with(@agg, [:a,:b,:c],{})
        @agg.facts_for([:a,:b,:c])
      end
    end

    context "instance methods" do
      setup do
        @instance = @agg[{ "a" => { "a"=>:b}}]
      end

      context "#dimension_names" do
        should "present dimension names as an array" do
          assert_equal ["a"], @instance.dimension_names
        end
      end

      context "#dimension_keys" do
        should "present dimension keys as an array" do
          assert_equal [:b], @instance.dimension_keys
        end
      end

      context "#add" do
        should "call update with the appropriate action" do
          @instance.expects(:update).with({:a=>:b},:add)
          @instance.add({:a=>:b})
        end
      end

      context "#reject" do
        should "call update with the appropriate action" do
          @instance.expects(:update).with({ :a=>:b}, :reject)
          @instance.reject({:a=>:b})
        end
      end

      context "#measure_changes_for" do
        setup do
          @added = @instance.send(:measure_changes_for,"a", 1000, "add")
          @rejected = @instance.send(:measure_changes_for,"a", 1000, "reject")
        end

        should "prepare a count component" do
          assert_equal 1, @added["measures"]["a"]["count"]
        end
        should "prepare a sum component" do
          assert_equal 1000, @added["measures"]["a"]["sum"]
        end
        should "prepare a sum2 component" do
          assert_equal 1000*1000, @added["measures"]["a"]["sum2"]
        end
        should "reverse the sign of the measures when the action is reject" do
          @rejected["measures"]["a"].values.each { |val| assert val < 0}
        end
      end

      context "#update" do
        should "prepare aggrgation data and submit it to store.update_aggregation" do
          expected = {
            :dimension_keys => [:b],
            :dimension_names => ["a"],
            :measures => {
              "measures"=>{"d" =>{
                  "count" => 1,
                  "sum" => 1000,
                  "sum2" => 1000*1000
                }}},
            :dimensions => { "a" => { "a"=>:b}}
          }

          @instance.class.store.expects(:update_aggregation).with(expected)
          @instance.send(:update, { "d" => 1000}, :add)

        end

      end

    end
  end
end
