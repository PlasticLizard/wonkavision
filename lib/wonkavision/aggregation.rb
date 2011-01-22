module Wonkavision
  module Aggregation

    def self.all
      Wonkavision::Plugins::Aggregation.all
    end

    def self.included(handler)
      handler.class_eval do
        extend Plugins
        use Plugins::Aggregation
#        use Plugins::EventHandling
#        use Plugins::Callbacks
      end

      super
    end
  end
end
