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
      assert_equal @facts, @store.facts
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


  end
end
