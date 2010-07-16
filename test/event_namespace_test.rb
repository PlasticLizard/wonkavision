require "test_helper"

class EventNamespaceTest < ActiveSupport::TestCase

  context "EventNamespace#namespace" do
    should "return the namespace if no arguments are provided" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns2 = Wonkavision::EventNamespace.new :ns2, ns1
      assert_equal ns1, ns2.namespace
    end
    should "create a new namespace with the provided name" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns2 = ns1.namespace :ns2
      assert_equal ns1, ns2.namespace
      assert_equal ns2, ns1.children[ns2.name] 
    end
    should "yield the new namespace for modification" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns2 = ns1.namespace(:ns2){|child|child.namespace(:ns3)}
      assert_equal 1, ns2.children.length
      assert_equal "ns3", ns2.children.keys[0]
    end
  end

  context "EventNamespace#event" do
    should "create a new event with the provided name" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.event :evt1
      assert_equal ns1, evt.namespace
      assert_equal evt, ns1.children[evt.name]
    end
    should "provide source_events to the new event if in the opts hash" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.event :evt1, :source_events=>"evt2"
      assert_equal "evt2", evt.source_events[0].name
    end
     should "yield new event to block if provided" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.event(:evt1) {|evt|evt.source_events "evt2"}
      assert_equal "evt2", evt.source_events[0].name
    end
  end

  context "EventNamespace#find_or_create" do
    should "find an existing direct child event" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.event :evt1
      assert_equal evt, ns1.find_or_create("evt1")
    end
    should "find a nested event" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.namespace(:ns2).event(:evt1)
      assert_equal evt, ns1.find_or_create("ns2/evt1")
    end
    should "find a direct child namespace" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns2 = ns1.namespace :ns2
      assert_equal ns2, ns1.find_or_create("ns2")
    end
    should "find a nested namespace" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns3 = ns1.namespace(:ns2).namespace(:ns3)
      assert_equal ns3, ns1.find_or_create("ns2/ns3")
    end
    should "create a top level child event if not found" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.find_or_create("TheNewEvent")
      assert_equal "ns1/the_new_event", evt.path
    end
    should "create a top level child namespace if not found" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns2 = ns1.find_or_create("TheNewNamespace",:namespace)
      assert_equal "ns1/the_new_namespace",ns2.path
    end
    should "create a nested event if namespace exits but event not found" do
      ns1 = Wonkavision::EventNamespace.new(:ns1)
      ns1.namespace :ns2
      evt = ns1.find_or_create("ns2/new_event")
      assert_equal "ns1/ns2/new_event",evt.path
    end
    should "create a nested namespace and event if not found" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = ns1.find_or_create("ns3/new_event")
      assert_equal "ns1/ns3/new_event",evt.path
      assert ns1.children["ns3"].children["new_event"]
    end
    should "create nested namespaces if not found" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns3 = ns1.find_or_create "not/found/my/friend",:namespace
      assert ns3.is_a?(Wonkavision::EventNamespace)
      assert_equal "ns1/not/found/my/friend", ns3.path
    end
  end
  context "EventNamespace#find_matching_values" do
    should "find all events matching the specified path" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      ns2 = ns1.namespace :ns2
      ns2.event "my_event"
      ns2.event :e1, "my_event"
      ns3 = ns2.namespace :ns3
      ns3.event :e2, "/ns2/my_event"
      ns4 = ns1.namespace :ns4
      ns4.event :e3, "/ns2/my_event"
      ns4.event "my_event"

      assert_equal 4, ns1.find_matching_events("ns1/ns2/my_event").length
    end
  end
end