require "test_helper"

class StoreTest < ActiveSupport::TestCase
  Store = Wonkavision::Analytics::Persistence::Store

  context "Store" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        include Wonkavision::Analytics::Facts
        record_id :tada
      end
      @store = Store.new(@facts)
    end

    should "provide access to the underlying owner" do
      assert_equal @facts, @store.owner
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

      context "#facts_for" do
        setup do
          Wonkavision::Analytics.context.global_filters <<  :dimensions.a.eq(:b)
        end
        teardown do
          Wonkavision::Analytics.context.global_filters.clear
        end
        should "append global filters and call fetch_facts" do
          @store.expects(:fetch_facts).with(:hi,[:a,:dimensions.a.eq(:b)],{ })
          @store.facts_for(:hi, [:a])
        end
      end

      context "#execute_query" do
        setup do
          @query = Wonkavision::Analytics::Query.new
          @query.select :a, :b, :on => :columns
          @query.select :c, :on => :rows
          @query.where :d=>:e
        end
        should "delegate to fetch tuples, passing the selected dimensions" do
          @store.expects(:fetch_tuples).with(['a','b','c', 'd'],@query.filters)
          @store.execute_query(@query)
        end
        should "pass an empty array of dimensions when nothing is selected" do
          @store.expects(:fetch_tuples).with([],[])
          @store.execute_query(Wonkavision::Analytics::Query.new)
        end
        context "when a global filter is applied" do
          setup do
            Wonkavision::Analytics.context.global_filters << :dimensions.a.eq(:b)
          end
          teardown do
            Wonkavision::Analytics.context.global_filters.clear
          end
          should "append global filters" do
            filters = @query.filters + [:dimensions.a.eq(:b)]
            @store.expects(:fetch_tuples).with(['a','b','c','d'],filters)
            @store.execute_query(@query)
          end
        end

      end
      context "Deriving from Store" do
        should "register the derived class with the superclass" do
          class NewStore < Store; end
          assert_equal NewStore, Store[:new_store]
        end
      end
    end

  end
end
