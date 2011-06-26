require "test_helper"

class EventTest < ActiveSupport::TestCase
  context "Event#matches" do
    should "correctly match based on name" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = Wonkavision::Event.new :evt1, ns1
      assert evt.matches("ns1/evt1")
    end
    should "correctly reject based on name" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt = Wonkavision::Event.new :evt1, ns1
      assert_equal false, evt.matches("ns1/evt2")
    end
    should "correctly reject based on namespace" do
       ns1 = Wonkavision::EventNamespace.new :ns1
      evt = Wonkavision::Event.new :evt1, ns1
      assert_equal false, evt.matches("ns2/evt1")  
    end
    should "correctly match based on non-nested source events" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt1 = ns1.event :evt1
      evt2 = ns1.event :evt2, evt1.name

      assert evt2.matches("ns1/evt1")
    end
    should "correctly match based on nested source events" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt1 = ns1.event :evt1
      evt2 = ns1.event :evt2, evt1.name
      evt3 = ns1.event :evt3, evt2.name

      assert evt3.matches("ns1/evt1")
    end
    should "correctly reject mismatched source events" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt1 = ns1.event :evt1
      evt2 = ns1.event :evt2, evt1.name
      evt3 = ns1.event :evt3, evt2.name

      assert_equal false, evt3.matches("ns1/evt4")
    end
  end
  context "Event#source_events" do
    should "resolve or create all provided paths" do
      ns1 = Wonkavision::EventNamespace.new :ns1
      evt1 = ns1.event :evt1
      evt2 = ns1.event :evt2
      evt2.source_events "evt1", "ns2/evt3", "evt4"

      assert_equal 3, evt2.source_events.length
    end
  end
end