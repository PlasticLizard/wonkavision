require "test_helper"

class HashStoreTest < ActiveSupport::TestCase
  HashStore = Wonkavision::Analytics::Persistence::HashStore

  context "HashStore" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        include Wonkavision::Analytics::Facts
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
      context "#facts_for" do
        setup do
          @agg = Class.new
          @agg.class_eval do
            include Wonkavision::Analytics::Aggregation
            dimension :simple
            dimension :less_simple, :from=>:russia
            dimension :with_love do
              caption :hi_there
            end
          end

          @store.send(:insert_facts_record,123,
                      {
                        "simple"=>"simon",
                        "russia"=>{ "less_simple"=>"seeriously"},
                        "with_love"=>{ "with_love"=>"ooooh","hi_there"=>"friend"}
                      })
          @store.send(:insert_facts_record,456,
                      {
                        "simple"=>"simon",
                        "russia"=>{ "less_simple"=>"seeriously"},
                        "with_love"=>{ "with_love"=>"ooooh","hi_there"=>"jebus"}
                      })
        end

        should "return facts a given set of filters" do
          filters = [:dimensions.simple.eq("simon"),:dimensions.with_love.caption.eq("jebus")]
          assert_equal 1, @store.send(:facts_for,@agg,filters).length
          assert_equal [@store[456]], @store.send(:facts_for,@agg,filters)
        end
        context "#attributes_for" do
          should "return return the original facts for measures" do
            filter = :measures.simple
            assert_equal @store[123], @store.send(:attributes_for,@agg,filter,@store[123])
          end
          should "return the original facts for simple dimensions" do
            filter = :dimensions.simple
            assert_equal @store[123], @store.send(:attributes_for,@agg,filter,@store[123])
          end
          should "return a nested object for dimensions with from specified" do
            filter = :dimensions.less_simple
            assert_equal @store[123]["russia"], @store.send(:attributes_for,@agg,filter,@store[123])
          end
          should "return a nested object for complex dimensions" do
            filter = :dimensions.with_love.caption
            assert_equal( @store[123]["with_love"],
                          @store.send(:attributes_for,@agg,filter,@store[123]) )
          end

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
          @update[:measures] = @update[:measures].merge("one" => 2.5)
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
