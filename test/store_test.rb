require "test_helper"

class StoreTest < ActiveSupport::TestCase
  Store = Wonkavision::Analytics::Persistence::Store

  context "Store" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        include Wonkavision::Facts
        record_id :tada
      end
      @store = Store.new(@facts)
    end

    should "provide access to the underlying facts specification" do
      assert_equal @facts, @store.facts
    end

    should "be able to extract a record_id from a message" do
      assert_equal 123, @store.send(:assert_record_id,{ "tada" => 123 })
    end

    should "raise an exception if a record_id is requested but not found" do
      assert_raise(RuntimeError) {  @store.send(:assert_record_id,{ "haha" => 123})}
    end

    context "Public api" do
      context "#update_facts" do
        should "extract a record_id and delegate to update_facts_record" do
          @store.expects(:update_facts_record).with(123,{ "tada"=>123})
          @store.update_facts("tada"=>123)
        end
      end
      context "#add_facts" do
        should "extract a record_id and delegate to insert_facts_record" do
          @store.expects(:insert_facts_record).with(123,{ "tada" => 123})
          @store.add_facts("tada"=>123)
        end
      end
      context "#remove_facts" do
        should "extract a record_id and delegate to delete_facts_record" do
          @store.expects(:delete_facts_record).with(123,{ "tada" => 123} )
          @store.remove_facts("tada"=>123)
        end
      end
    end
  end
end
