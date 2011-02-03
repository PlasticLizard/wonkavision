# This sample works best with JRuby, as it uses a multi-threaded job queue
# for processing work.
#
#  On my machine, 10,000 messages aggregate in 60s on JRuby, 133 on 1.9.2
#  and 200 on 1.8.7.
#
#  Without using the multi-threaded job queue, it takes 106.1 seconds on 1.8.7 and 94 seconds
#  on JRuby. I did not test 1.8.7 in that scenario. JRuby take a while to warm up though,
#  so it performs worse for low numbers of messages, taking a few thousand before it gets its stride.
#
#
#
dir = File.expand_path(File.dirname(__FILE__))
require File.join dir, "../lib/wonkavision"
require File.join dir, "../lib/wonkavision/plugins/analytics/mongo"

Wonkavision::Mongo.database = "analytics_test"
Wonkavision.event_coordinator.job_queue = Wonkavision::LocalJobQueue.new


class TestFacts
  include Wonkavision::Facts

  store :mongo_store
  record_id :_id

  accept 'test/event' do
    value :_id
    string :color, :size, :shape
    float :weight
    float :cost => context["the_cost"]
  end

end

class TestAggregation
  include Wonkavision::Aggregation

  store :mongo_store

  aggregates TestFacts

  dimension :color, :size, :shape
  measure :weight, :cost

  aggregate_by :color
  aggregate_by :size
  aggregate_by :shape
  aggregate_by :color, :size
  aggregate_by :color, :shape
  aggregate_by :size, :shape
  aggregate_by :size, :color, :shape

  @i = 0
  def self.send_messages
    colors = %w(red green red green yellow black black white red yellow)
    sizes =  %w(large large small medium medium small large small medium small)
    shapes = %w(square circle rectangle rectangle circle square circle rectangle square square)
    weights =  [1.0, 2.0, 1.1, 2.1, 1.2, 2.2, 1.3, 2.3,4.5,6.5]
    costs =    [5, 10, 15, 20, 15, 20, 5, 8, 9, 20]

    (0..9).each do |idx|
      Wonkavision.event_coordinator.submit_job "test/event",  {
        "_id" => BSON::ObjectId.new,
        "color" => colors[idx],
        "size" => sizes[idx],
        "shape" => shapes[idx],
        "weight" => weights[idx],
        "the_cost" => costs[idx].to_s
      }
      @i+=1
      print @i % 50 == 0 ? @i : "."
    end

  end
end

TestFacts.store.facts_collection.drop
TestAggregation.store.aggregations_collection.drop
total = Time.now
200.times do |idx|
  puts "Pass #{idx+1}"
  time = Time.now
  5.times { TestAggregation.send_messages }
  puts "\n"
  puts Time.now - time

  puts "Facts: #{TestFacts.store.facts_collection.count}"
  puts "Aggregations: #{TestAggregation.store.aggregations_collection.count}"
  puts "\n"

end
while Wonkavision.event_coordinator.job_queue.queue.length > 0
  sleep 0.1
  print "[#{Wonkavision.event_coordinator.job_queue.queue.length}]"
end
puts "Total time #{Time.now - total}"


# SELECT Size * Shape on Columns, Color on Rows
# SELECT Size * Shape ON Columns, Color ON Rows WHERE Color.&red

