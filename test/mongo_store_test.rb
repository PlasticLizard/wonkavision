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
      assert_equal @facts, @store.facts
    end

    should "create a collection name based on the facts class name" do
      assert_equal "wv.test_facts.facts", @store.collection_name
    end


    context "Facts persistence" do
      setup do
        @doc_id = BSON::ObjectId.new
        @store.collection.insert( {"_id" => @doc_id,
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

    end


  end
end
