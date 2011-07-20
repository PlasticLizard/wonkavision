require "test_helper"

class FactsTest < ActiveSupport::TestCase
  context "Facts" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts" end
        include Wonkavision::Analytics::Facts
        record_id :_id
        
        accept 'some/event/path'
        
        accept 'another/event/path/rejected', :action => :reject do
          float :mapped
        end

        snapshot :daily, :every => "1h" do
          key_name "hi"
        end

        dynamic do
          context_time = options.context_time || Date.today.to_utc_time
          integer :huh => context_time
          time :now => Time.now
          integer :hi
        end

      end
    end

    should "configure an aggregation set" do
      assert_not_nil @facts.aggregations
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
        assert_equal 3, @facts.bindings.length
        assert_equal 'some/event/path', @facts.bindings[0].events[0]
        assert_equal 'another/event/path/rejected', @facts.bindings[1].events[0]
      end

      should "configure a message map when a block is provided to 'accept'" do
        assert_equal 1, @facts.maps.length
        assert_equal "another/event/path/rejected", @facts.maps[0][0]
      end

    end

    context "#snapshot" do
      should "configure a binding for the snapshot" do
        assert_equal "wv.my_facts.snapshot.daily", @facts.bindings[2].events[0]
      end
      should "intantiate and store a snapshot" do
        assert_equal 1, @facts.snapshots.length
        assert_equal :daily, @facts.snapshots[:daily].name
        assert_equal "1h", @facts.snapshots[:daily].options[:every]
      end
      should "accept config from the block" do
        assert_equal "hi", @facts.snapshots[:daily].key_name
      end
    end

    context "#facts_for" do
      should "pass arguments to underlying storage" do
        @facts.store :hash_store
        @facts.store.expects(:facts_for).with("agg",[:a,:b,:c],{})
        @facts.facts_for("agg",[:a,:b,:c])
      end
    end

    context "#dynamic" do
      should "store the mapping block in the dynamic fields property" do
        assert @facts.dynamic.kind_of?(Proc)
      end
      should "store a map name instead if provided" do
        @facts.dynamic :other_dynamic do
        end
        assert_equal :other_dynamic, @facts.dynamic
      end
    end

    context "#apply_dynamic" do
      should "execute the dynamic map against the facts according to the options" do
        context_time = Date.today.to_utc_time
        result = @facts.apply_dynamic({:hi => "3", :ho=>"hum"},
                                      :context_time => context_time)
        assert_equal 3, result["hi"]
        assert_equal "hum", result[:ho]
        assert result["now"] <= Time.now
        assert_equal context_time.to_i, result["huh"]
      end
    end

    context "#apply_dynamic_fields" do
    end

    context "instance methods" do
      setup do
        @instance = @facts.new
      end
      context "#accept_event" do
        should "defer to add_fact by default" do
          @instance.expects(:add_facts).with({:hi=>:there})
          @instance.accept_event(:hi=>:there)
        end
        should "defer to the appropriate method based on the action option" do
          @instance.expects(:reject_facts).with({:hi=>:there})
          @instance.accept_event({ :hi=>:there}, :action=>:reject)
        end
        should "ignore facts that do not match the filter criteria" do
          @facts.filter { |facts, action| facts[:hi] != :there }
          @instance.expects(:add_facts).with({:hi=>:there}, nil).times(0)
          @instance.accept_event({ :hi=>:there})
        end
        should "allow facts that do match the filter criteria" do
          @facts.filter { |facts, action|facts[:hi] == :there}
          @instance.expects(:add_facts).with({:hi=>:there}).times(1)
          @instance.accept_event({ :hi=>:there})
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
          @instance.expects(:process_facts).with({ "_id"=>123}, "reject", nil)
          @instance.update_facts({ "_id"=>123})
        end
        should "process an addition of current_facts are returned" do
          store = {}
          @instance.expects(:store).times(2).returns(store)
          store.expects(:update_facts).returns([nil,{ "_id"=>123}])
          @instance.expects(:process_facts).with({ "_id"=>123}, "add", nil)
          @instance.update_facts({ "_id"=>123})
        end

      end

      context "#add_facts" do
        should "call #process_facts with the correct action" do
          @instance.expects(:process_facts).with({ :hi=>:there}, "add", nil)
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
          @instance.expects(:process_facts).with({ :hi=>:there}, "reject", nil)
          @instance.reject_facts(:hi=>:there)
        end
        should "remove the facts from a store if configured" do
          store = {}
          @instance.expects(:store).times(2).returns(store)
          store.expects(:remove_facts).with({ "_id"=>123})
          @instance.reject_facts("_id"=>123)
        end

      end

      context "#snapshot_facts" do
        should "call #process_facts with the correct action and the snapshot" do
          @instance.expects(:process_facts).with({:hi=>:there}, "add", :snappy)
          @instance.snapshot_facts({:hi=>:there}, :snappy)
        end
      end

      context "#process_facts" do
        should "submit a copy of the message once for each aggregation" do
          aggs = [stub(:aggregation), stub(:aggregation)]
          aggs.each { |a| a.expects(:aggregate!) }
          @facts.aggregations.concat aggs
          @instance.send(:process_facts,{ :hi=>:there}, "add")
        end
        should "submit each event using the output event path, action and message" do
          agg = stub(:aggregation)
          @facts.aggregations << agg
          agg.expects(:aggregate!).with({"hi"=>"there"},"add",nil)
          @instance.send(:process_facts, { "hi"=>"there"}, "add")
        end
      end

    end

  end
end
