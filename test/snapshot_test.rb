require "test_helper"

class SnapshotTest < ActiveSupport::TestCase
  context "Snapshot" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts" end
        include Wonkavision::Analytics::Facts
        record_id :_id
        snapshot :daily, :query => {"a" => "b"}
        store :hash_store
      end

      @snapshot = @facts.snapshots[:daily]
    end

    should "take its default event name from the facts" do
      assert_equal "wv.my_facts.snapshot.daily", @snapshot.event_name
    end

    context "take!" do

      should "query the store for facts matching the query" do
        @facts.store.expects(:each).with({"a"=>"b"}).returns([])
        @snapshot.take!(Date.today.to_utc_time)
      end

      should "iterate over the facts and broadcast them" do
        store = DummyStore.new([1,2,3,nil]) #the nill simulates em_mongo.each results
        @facts.expects(:store).returns(store)
        snapshot_time = Date.today.to_utc_time
        @snapshot.expects(:submit_snapshot).with(1, snapshot_time, {})
        @snapshot.expects(:submit_snapshot).with(2, snapshot_time, {})
        @snapshot.expects(:submit_snapshot).with(3, snapshot_time, {})
        @snapshot.take!(Date.today.to_utc_time)
        assert_equal( {"a"=>"b"}, store.query )
      end

    end

    context "submit_snapshot" do
      should "prepare and publish the snapshot" do
        msg = {"a"=>"b"}
        snapshot_time = Date.today.to_utc_time
        @snapshot.expects(:prepare_snapshot).with(msg,snapshot_time,{}).returns(msg)
        @snapshot.expects(:publish).with(msg)
        @snapshot.send(:submit_snapshot, msg, snapshot_time, {})
      end
    end

    context "prepare_snapshot" do
      should "apply facts calculations using the context time and merge in the snapshot_time key" do
        msg = {"a"=>"b"}
        opts = {:context_time => Date.today.to_utc_time}
        @facts.expects(:apply_dynamic).with(msg, opts).returns(msg)
        expected = {
          "a"=>"b",
          "snapshot_time" => @snapshot.send(:snapshot_key, Date.today.to_utc_time)
        }
        assert_equal expected, @snapshot.send(:prepare_snapshot, msg, Date.today.to_utc_time, {})
      end
    end

    context "snapshot_key" do
      should "prepare an expanded time dimension" do
        time = Time.parse("2011-07-19T00:00:00Z")
        expected = {
          "timestamp" => time,
          "day_key" => "2011-07-19",
          "month_key" => "2011-07",
          "year_key" => 2011,
          "day_of_month" => 19,
          "day_of_week" => 2,
          "month" => 7
        }
        assert_equal expected, @snapshot.send(:snapshot_key, time)
      end
    end
  
  end
end

class DummyStore
  attr_accessor :query, :data
  
  def initialize(data)
    @data = data
  end

  def each(query)
    @query = query
    @data.each { |item| yield item }
  end
end