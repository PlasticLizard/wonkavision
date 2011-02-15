require "test_helper"

class MongoStoreTest < ActiveSupport::TestCase
  MongoStore = Wonkavision::Analytics::Persistence::MongoStore

  context "MongoStore" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "TestFacts"; end
        include Wonkavision::Facts
        record_id :tada
      end
      @store = MongoStore.new(@facts)
    end

    should "provide access to the underlying facts specification" do
      assert_equal @facts, @store.owner
    end

    should "create a collection name based on the facts class name" do
      assert_equal "wv.test_facts.facts", @store.facts_collection_name
    end


    context "Facts persistence" do
      setup do
        @doc_id = 123
        @store.facts_collection.insert( {"_id" => @doc_id,
                                    "tada" => @doc_id,
                                    "todo" => "hoho",
                                    "canttouchthis"=>"yo"} )
      end
      context "#update_facts_record" do
        setup do
          @prev,@cur = @store.send( :update_facts_record,
                                    @doc_id, "tada"=>@doc_id, "todo"=>"heehee", "more"=>"4me?" )
        end
        should "return the previous version of the facts record" do
          assert_equal( { "tada" => @doc_id, "todo" => "hoho", "canttouchthis"=>"yo"}, @prev  )
        end
        should "return the updated version of the facts record" do
          assert_equal({ "tada" => @doc_id, "todo" => "heehee", "canttouchthis"=>"yo","more"=>"4me?"},
                       @cur)
        end
        should "contain the upated version in the storage" do
          assert_equal({ "_id"=>@doc_id, "tada" => @doc_id, "todo" => "heehee", "canttouchthis"=>"yo","more"=>"4me?"},
                       @store[@doc_id])
        end
      end
      context "#insert_facts_record" do
        setup do
          @cur = @store.send(:insert_facts_record,@doc_id,{ "tada"=>@doc_id,"i is"=>"new"})
        end
        should "return the current version of the facts record" do
          assert_equal( { "tada"=>@doc_id,"i is"=>"new"}, @cur )
        end
        should "add the record to the storage" do
          assert_equal @cur.merge("_id"=>@doc_id), @store[@doc_id]
        end
      end
      context "#delete_facts_record" do
        setup do
          @prev = @store.send(:delete_facts_record,@doc_id,{"tada"=>@doc_id})
        end
        should "return the previous version of the facts record" do
          assert_equal( { "tada" => @doc_id, "todo" => "hoho", "canttouchthis"=>"yo"}, @prev  )
        end
        should "remove the facts record from the storage" do
          assert_nil @store[@doc_id]
        end

      end

      context "#facts_for" do
        setup do
          @agg = Class.new
          @agg.class_eval do
            include Wonkavision::Aggregation
            dimension :simple
            dimension :less_simple, :from=>:russia
            dimension :with_love do
              caption :hi_there
            end
          end

          @store.send(:insert_facts_record,123,
                      {
                        "simple"=>"simon",
                        "russia"=>{ "less_simple"=>"seriously?"},
                        "with_love"=>{ "with_love"=>"ooooh","hi_there"=>"friend"}
                      })
          @store.send(:insert_facts_record,456,
                      {
                        "simple"=>"simon",
                        "russia"=>{ "less_simple"=>"seriously!"},
                        "with_love"=>{ "with_love"=>"ooooh","hi_there"=>"jebus"}
                      })
        end

        should "return facts a given set of filters" do
          filters = [:dimensions.simple.eq("simon"),:dimensions.with_love.caption.eq("jebus")]
          assert_equal 1, @store.send(:facts_for,@agg,filters).length
          assert_equal [@store[456]], @store.facts_for(@agg,filters)
        end
        should "return facts that match a given simple filter" do
          filters = [:dimensions.simple.eq("simon")]
          assert_equal 2, @store.facts_for(@agg,filters).length
        end
        should "return facts that utilize a 'from' filter" do
          filters = [:dimensions.less_simple.eq("seriously!")]
          assert_equal [@store[456]], @store.facts_for(@agg,filters)
        end
        should "return facts that utilize a measure filter" do
          filters = [:measures.simple.gt("a")]
          assert_equal 2, @store.facts_for(@agg,filters).length
        end
        should "exclude facts that don't match a measure filter" do
          filters = [:measures.simple.lt("a")]
          assert_equal 0, @store.facts_for(@agg,filters).length
        end
        context "pagination" do
          filters = [:dimensions.simple.eq("simon")]
          should "return only per-page records when specified" do
            assert_equal 1, @store.facts_for(@agg, filters, :per_page=>1).length
          end
          should "configure the results with pagination related properties" do
            filters = [:dimensions.simple.eq("simon")]
            results = @store.facts_for(@agg, filters, :per_page =>1, :page=>2)
            assert_equal 2, results.total_pages
            assert_equal 2, results.current_page
            assert_equal 2, results.total_entries
            assert_equal nil, results.next_page
            assert_equal 1, results.previous_page
          end
          should "fetch the correct records per page" do
            results = @store.facts_for(@agg,[],:per_page=>1, :sort=>[:_id,1])
            assert_equal 123, results[0]["_id"]
            results = @store.facts_for(@agg,[],
                                       :per_page=>1,
                                       :sort=>[:_id,1],
                                       :page=>results.next_page)
            assert_equal 456, results[0]["_id"]
          end

        end


      end

      context "#where" do
        setup do
           @store.send(:insert_facts_record,123,
                      {
                        "simple"=>"simon",
                        "russia"=>{ "less_simple"=>"seriously?"},
                        "with_love"=>{ "with_love"=>"ooooh","hi_there"=>"friend"}
                      })
          @store.send(:insert_facts_record,456,
                      {
                        "simple"=>"simon",
                        "russia"=>{ "less_simple"=>"seriously!"},
                        "with_love"=>{ "with_love"=>"ooooh!","hi_there"=>"jebus"}
                      })
        end
        should "select records using the provided criteria" do
          results = @store.where :simple=>:simon, "with_love.with_love" => "ooooh"
          assert_equal [@store[123]], results
        end
        context "#count" do
          should "return the total number of records with no criteria" do
            assert_equal 2, @store.count
          end
          should "return the number of records matching the criteria" do
            assert_equal 1, @store.count({ :simple=>:simon, "with_love.with_love" => "ooooh" })
          end

        end

      end


    end
    context "Aggregations persistence" do
      setup do
        @tuple  = { :dimension_keys=>[1,2,3],
          :dimension_names=>[:a,:b,:c],
          :dimensions=>{"dims"=>"doms"},
          :measures=>{ "measures.one"=>1} }
      end
      context "#update_tuple" do
        should "insert a new tuple if not present" do
          @store.send(:update_tuple, @tuple)
          added = @store.aggregations_collection.find({ :dimension_names=>[:a,:b,:c] }).to_a[0]
          added.delete("_id") #isn't present on the original, we know its there
          assert_equal @tuple.merge({:measures=>{ "one" => 1}}).stringify_keys!, added
        end
      end
      context "#append_aggregations_filters" do
        setup do
          @dim_filter = Wonkavision::Analytics::MemberFilter.new("tada",:value=>[1,2,3])
          @measure_filter = Wonkavision::Analytics::MemberFilter.new("haha",
                                                                     :member_type=>:measure,
                                                                     :op=>:gte,
                                                                     :value=>100.0)
          @criteria = {}
          @dim_filter.expects(:attribute_key).returns "tada_key"
          @store.send(:append_aggregations_filters,@criteria,[@dim_filter,@measure_filter])
        end
        should "prepare the dimension filter for mongodb" do
          assert_equal( [1,2,3], @criteria["dimensions.tada.tada_key"] )
        end
        should "prepare the measure filter for mongodb" do
          assert_equal( { "$gte" => 100.0 }, @criteria["measures.haha.count"] )
        end


      end

    end

  end
end
