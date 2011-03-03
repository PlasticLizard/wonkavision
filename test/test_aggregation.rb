class TestAggregation
  include Wonkavision::Aggregation

  store :hash_store

  dimension :color, :size, :shape
  measure :weight, :default_to=>:average, :format=>:float,:precision=>2
  measure :cost, :default_to=>:sum, :format=>:float, :precision=>1

  calc :cost_weight do
    cost + weight.sum
  end

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
      Wonkavision.event_coordinator.submit_job "wv/analytics/entity/updated",  {
        "aggregation" => "TestAggregation",
        "action" => "add",
        "entity" => {
          "color" => colors[idx],
          "size" => sizes[idx],
          "shape" => shapes[idx],
          "weight" => weights[idx],
          "cost" => costs[idx]
        }
      }
      @i+=1
      print @i % 100 == 0 ? @i : "."
    end

  end
end
