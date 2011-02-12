require "test_helper"

class FactsTest < ActiveSupport::TestCase
  context "Facts" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts" end
        include Wonkavision::Facts
        record_id :_id
        accept 'some/event/path'
        accept 'another/event/path/rejected', :action => :reject do
          float :mapped
        end

      end
    end

    should "configure an aggregation set" do
      assert_not_nil @facts.aggregations
    end

    should "set a default output event path based on class name" do
      assert_equal "wv/analytics/facts/updated", @facts.output_event_path
    end

    should "accept an alternative output event path" do
      @facts.output_event_path "something/else"
      assert_equal "something/else", @facts.output_event_path
    end

    should "present the configured record id" do
      assert_equal :_id, @facts.record_id
    end

    should "set the specified storage" do
      @facts.store :hash_store
      assert @facts.store.kind_of?(Wonkavision::Analytics::Persistence::HashStore)
      assert_equal @facts, @facts.store.owner
    end

    context "#accept" do

      should "configure a binding for each 'accept' directive" do
        assert_equal 2, @facts.bindings.length
        assert_equal 'some/event/path', @facts.bindings[0].events[0]
        assert_equal 'another/event/path/rejected', @facts.bindings[1].events[0]
      end

      should "configure a message map when a block is provided to 'accept'" do
        assert_equal 1, @facts.maps.length
        assert_equal "another/event/path/rejected", @facts.maps[0][0]
      end

    end

    context "#facts_for" do
      should "pass arguments to underlying storage" do
        @facts.store :hash_store
        @facts.store.expects(:facts_for).with("agg",[:a,:b,:c])
        @facts.facts_for("agg",[:a,:b,:c])
      end
    end


    context "instance methods" do
      setup do
        @instance = @facts.new
      end
      context "#accept_event" do
        should "defer to add_fact by default" do
          @instance.expects(:add_facts).with(:hi=>:there)
          @instance.accept_event(:hi=>:there)
        end
        should "defer to the appropriate method based on the action option" do
          @instance.expects(:reject_facts).with(:hi=>:there)
          @instance.accept_event({ :hi=>:there}, :action=>:reject)
        end
      end
      context "#update_facts" do
        should "fail unless a store is configured" do
          assert_raise(RuntimeError) {  @instance.update_facts({"_id"=>123})}
        end
        should "update the store" do
          @instance.expects(:update_facts).with({ "_id"=>123}).returns([nil,nil])
          @instance.update_facts({ "_id"=>123})
        end
        should "process a rejection if previous_facts are returned" do
          store = {}
          @instance.expects(:store).times(2).returns(store)
          store.expects(:update_facts).returns([{ "_id"=>123},nil])
          @instance.expects(:process_facts).with({ "_id"=>123}, "reject")
          @instance.update_facts({ "_id"=>123})
        end
        should "process an addition of current_facts are returned" do
          store = {}
          @instance.expects(:store).times(2).returns(store)
          store.expects(:update_facts).returns([nil,{ "_id"=>123}])
          @instance.expects(:process_facts).with({ "_id"=>123}, "add")
          @instance.update_facts({ "_id"=>123})
        end

      end

      context "#add_facts" do
        should "call #process_facts with the correct action" do
          @instance.expects(:process_facts).with({ :hi=>:there}, "add")
          @instance.add_facts(:hi=>:there)
        end
        should "add the facts to a store if configured" do
          store = {}
          @instance.expects(:store).times(2).returns(store)
          store.expects(:add_facts).with({ "_id" => 123})
          @instance.add_facts("_id"=>123)
        end

      end
      context "#reject_facts" do
        should "call #process_facts with the correct action" do
          @instance.expects(:process_facts).with({ :hi=>:there}, "reject")
          @instance.reject_facts(:hi=>:there)
        end
        should "remove the facts from a store if configured" do
          store = {}
          @instance.expects(:store).times(2).returns(store)
          store.expects(:remove_facts).with({ "_id"=>123})
          @instance.reject_facts("_id"=>123)
        end

      end
      context "#process_facts" do
        should "submit a copy of the message once for each action * each aggregation" do
          @facts.aggregations << String
          @facts.aggregations << Hash
          @instance.expects(:submit).times(4)
          @instance.send(:process_facts,{ :hi=>:there}, "add", "reject")
        end
        should "submit each event using the output event path, action and message" do
          @facts.aggregations << String
          @instance.expects(:submit).with(@facts.output_event_path,{
                                            "action" => "add",
                                            "aggregation" => "String",
                                            "data" => { "hi" => "there"}
                                          })
          @instance.send(:process_facts, { "hi"=>"there"}, "add")
        end


      end

    end

  end
end
