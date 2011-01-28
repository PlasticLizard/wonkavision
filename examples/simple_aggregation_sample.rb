dir = File.expand_path(File.dirname(__FILE__))
require File.join dir, "../lib/wonkavision"

Wonkavision::Aggregation.persistence = :mongo
Wonkavision::Mongo.database = "analytics_test"


class TestAggregation
  include Wonkavision::MongoAggregation

  dimension :color, :size
  measure :weight, :cost

  aggregate_by :color
  aggregate_by :size
  aggregate_by :color, :size

  def self.send_messages
    colors = %w(red green red green yellow black black white red yellow)
    sizes =  %w(large large small medium medium small large small medium small)
    weights =  [1.0, 2.0, 1.1, 2.1, 1.2, 2.2, 1.3, 2.3,4.5,6.5]
    costs =    [5, 10, 15, 20, 15, 20, 5, 8, 9, 20]

    (0..9).each do |idx|
      Wonkavision.event_coordinator.submit_job "wv/analytics/entity/updated",  {
        "aggregation" => "TestAggregation",
        "action" => "add",
        "entity" => {
          "color" => colors[idx],
          "size" => sizes[idx],
          "weight" => weights[idx],
          "cost" => costs[idx]
        }
      }
    end

  end
end

TestAggregation.data_collection.drop

10.times { TestAggregation.send_messages }

puts "Created #{TestAggregation.data_collection.count} records"
