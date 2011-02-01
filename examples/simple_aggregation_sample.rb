dir = File.expand_path(File.dirname(__FILE__))
require File.join dir, "../lib/wonkavision"

Wonkavision::Aggregation.persistence = :mongo
Wonkavision::Mongo.database = "analytics_test"

class TestFacts
  include Wonkavision::Facts

  accept 'test/event' do
    string :color, :size, :shape
    float :weight
    float :cost => context["the_cost"]
  end

end

class TestAggregation
  include Wonkavision::MongoAggregation

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
        "color" => colors[idx],
        "size" => sizes[idx],
        "shape" => shapes[idx],
        "weight" => weights[idx],
        "the_cost" => costs[idx].to_s
      }
      @i+=1
      print @i % 100 == 0 ? @i : "."
    end

  end
end

TestAggregation.data_collection.drop

time = Time.now
10.times { TestAggregation.send_messages }
puts "\n"
puts Time.now - time

puts "Created #{TestAggregation.data_collection.count} records"


# SELECT Size * Shape on Columns, Color on Rows
# SELECT Size * Shape ON Columns, Color ON Rows WHERE Color.&red

