module Wonkavision
  module MongoAggregation

    def self.included(handler)
      handler.class_eval do
        extend Plugins
        use Plugins::Aggregation
        use Plugins::MongoAggregation
      end

      super
    end
  end

end
