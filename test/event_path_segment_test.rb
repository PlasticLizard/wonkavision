require "test_helper"

class EventPathSegmentTest < ActiveSupport::TestCase
  context "EventPathSegment#path" do
    should  "not include path segments for root segments" do
      assert_equal "a_segment", Wonkavision::EventPathSegment.new(:a_segment).path
    end
    should "join the parent namespace in the path for non root segments" do
      ns1 = Wonkavision::EventPathSegment.new(:ns_1)
      ns2 = Wonkavision::EventPathSegment.new(:ns_2, ns1)
      assert_equal "ns_1/ns_2/a_segment", Wonkavision::EventPathSegment.new(:a_segment,ns2).path
    end
    should "ignore segments in a hierarchy with a nil name" do
      ns1 = Wonkavision::EventPathSegment.new(:ns_1)
      ns2 = Wonkavision::EventPathSegment.new(nil,ns1)
      assert_equal "ns_1/a_segment", Wonkavision::EventPathSegment.new(:a_segment,ns2).path
    end
  end

  context "EventPathSegment#subscribe" do
    should "Add the provided block to the list of subscribers" do
      seg = Wonkavision::EventPathSegment.new
      x = 1
      seg.subscribe {x+=1 }
      assert_equal 1, seg.subscribers.length
      seg.subscribers[0].call
      assert_equal 2, x
    end
  end

  context "EventPathSegment#notifiy_subscribers" do
    should "call each subscribed block" do
      seg = Wonkavision::EventPathSegment.new
      x = 1
      seg.subscribe {x+=1}
      seg.subscribe {|data,path|x+=data+path}
      seg.notify_subscribers(5,2)

      assert_equal 9, x
    end    
  end
end