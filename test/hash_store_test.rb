require "test_helper"

class HashStoreTest < ActiveSupport::TestCase
  HashStore = Wonkavision::Analytics::Persistence::HashStore

  context "HashStore" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        include Wonkavision::Facts
        record_id :tada
      end
      @store = HashStore.new(@facts)
    end

    should "provide access to the underlying facts specification" do
      assert_equal @facts, @store.owner
    end

    context "Facts persistence" do
      setup do
        @store.storage[123] = { "tada" => 123, "todo" => "hoho", "canttouchthis"=>"yo"}
      end
      context "#update_facts_record" do
        setup do
          @prev,@cur = @store.send( :update_facts_record,
                                    123, "tada"=>123, "todo"=>"heehee", "more"=>"4me?" )
        end
        should "return the previous version of the facts record" do
          assert_equal( { "tada" => 123, "todo" => "hoho", "canttouchthis"=>"yo"}, @prev  )
        end
        should "return the updated version of the facts record" do
          assert_equal({ "tada" => 123, "todo" => "heehee", "canttouchthis"=>"yo","more"=>"4me?"},
                       @cur)
        end
        should "contain the upated version in the storage" do
          assert_equal({ "tada" => 123, "todo" => "heehee", "canttouchthis"=>"yo","more"=>"4me?"},
                       @store.storage[123])
        end
      end
      context "#insert_facts_record" do
        setup do
          @cur = @store.send(:insert_facts_record,123,{ "tada"=>123,"i is"=>"new"})
        end
        should "return the current version of the facts record" do
          assert_equal( { "tada"=>123,"i is"=>"new"}, @cur )
        end
        should "add the record to the storage" do
          assert_equal @cur, @store.storage[123]
        end
      end
      context "#delete_facts_record" do
        setup do
          @prev = @store.send(:delete_facts_record,123,{"tada"=>123})
        end
        should "return the previous version of the facts record" do
          assert_equal( { "tada" => 123, "todo" => "hoho", "canttouchthis"=>"yo"}, @prev  )
        end
        should "remove the facts record from the storage" do
          assert_nil @store.storage[123]
        end

      end

    end
    context "Aggregations persistence" do
      setup do
        @store.aggregations[{ :dimension_keys=>[1,2,3],:dimension_names=>[:a,:b,:c] }] =
          { :dimension_keys=>[1,2,3],
          :dimension_names=>[:a,:b,:c],
          :dimensions=>"dims",
          :measures=>{ "one"=>1} }
        @store.aggregations[{ :dimension_keys=>[1,2],:dimension_names=>[:a,:b] }] =
          { :dimension_keys=>[1,2],
          :dimension_names=>[:a,:b],
          :dimensions=>"dims",
          :measures=>{ "one"=>1} }

      end
      context "#fetch_tuples" do
        should "return tuples for the selected dimension intersections" do
          tuples = @store.send(:fetch_tuples,[:a,:b])
          assert_equal 1, tuples.length
          assert_equal( [@store.aggregations[{ :dimension_keys=>[1,2],:dimension_names=>[:a,:b] }]],
                        tuples )
        end
        should "return all tuples when no dimension names are specified" do
          assert_equal @store.aggregations.values, @store.send(:fetch_tuples,[])
        end
      end
      context "update_tuple" do
        setup do
          @update = @store.send(:fetch_tuples,[:a,:b])[0].dup
          @update[:measures].merge!("one" => 2.5)
        end

        should "aggregate an existing tuple if present" do
          @store.send(:update_tuple,@update)
          assert_equal 3.5, @store.send(:fetch_tuples,[:a,:b])[0][:measures]["one"]
        end
        should "insert a new tuple if not present" do
          @update[:dimension_keys] << 4
          @update[:dimension_names] << :d
          @store.send(:update_tuple,@update)
          assert_equal 2.5, @store.send(:fetch_tuples,[:a,:b,:d])[0][:measures]["one"]
        end


      end
    end
  end
end
