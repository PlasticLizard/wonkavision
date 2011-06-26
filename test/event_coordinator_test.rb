require "test_helper"

class EventCoordinatorTest < ActiveSupport::TestCase
  context "EventCoordinator.join" do
    should "Join all arguments with the path separator" do
      Wonkavision.event_path_separator = '.'
      assert_equal "one.two.three", Wonkavision.join("one","two","three")
      Wonkavision.event_path_separator = '/'
    end
    should "Ignore nil elements in the arguments" do
      assert_equal "one/two/three", Wonkavision.join('',nil,'one',nil,'two','','three')
    end
   
  end
  
  context "EventCoordinator#map" do
    should "yield the root namespace for configuration" do
      evt = nil
      Wonkavision.event_coordinator.map do |events|
        evt = events.event :event1
      end
      assert_equal evt, Wonkavision.event_coordinator.root_namespace.children["event1"]
    end
  end
  context "EventCoordinator#subscribe" do
    should "find an existing event and subscribe the provided block" do
      Wonkavision.event_coordinator.map do |events|
        events.event :my_event
      end  
      data = nil
      Wonkavision.event_coordinator.subscribe("my_event") {|d,p|data=d}
      Wonkavision.event_coordinator.root_namespace.children["my_event"].subscribers[0].call("hi","ho")
      assert_equal "hi",data
    end
    should "create a missing namespace, and subscribe the provided block" do
      data = nil
      Wonkavision.event_coordinator.subscribe("my_namespace",:namespace){data="hi"}
      Wonkavision.event_coordinator.root_namespace.children["my_namespace"].subscribers[0].call
      assert_equal "hi",data
      assert Wonkavision.event_coordinator.root_namespace.children["my_namespace"].is_a?(Wonkavision::EventNamespace)
    end
  end
  context "EventCoordinator#publish" do
    should "call notify_subscribers on all subscribers" do
      Wonkavision.event_coordinator.map do |events|
        events.namespace :ns1 do |ns1|
          ns1.event :event_one
          ns1.event :event_two, "event_one"
          ns1.event :event_three
        end
      end
      x = Hash.new{|hash,key|hash[key]=[]}
      Wonkavision.event_coordinator.subscribe("ns1/event_one") {|data,path|x[path]<<data}
      Wonkavision.event_coordinator.receive_event("ns1/event_one",1)
      assert_equal 1, x.length
      assert x.keys.include?("ns1/event_one")
      assert_equal 1, x["ns1/event_one"].length
      Wonkavision.event_coordinator.subscribe("ns1/event_two") {|data,path|x[path]<<data}
      Wonkavision.event_coordinator.receive_event("ns1/event_one",2)
      assert_equal 2, x.length
      assert_equal 2, x["ns1/event_one"].length
      assert_equal 1, x["ns1/event_two"].length
    end
  end
end