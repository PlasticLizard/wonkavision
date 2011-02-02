dir = File.expand_path(File.dirname(__FILE__))
require File.join dir, "../lib/wonkavision"
require File.join dir, "../lib/wonkavision/plugins/analytics/mongo"

Wonkavision::Mongo.database = "analytics_test"

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

5.times do |idx|
  puts "Pass #{idx+1}"
  time = Time.now
  5.times { TestAggregation.send_messages }
  puts "\n"
  puts Time.now - time

  puts "Facts: #{TestFacts.store.facts_collection.count}"
  puts "Aggregations: #{TestAggregation.store.aggregations_collection.count}"
  puts "\n"

end


# SELECT Size * Shape on Columns, Color on Rows
# SELECT Size * Shape ON Columns, Color ON Rows WHERE Color.&red

