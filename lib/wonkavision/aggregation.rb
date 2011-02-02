module Wonkavision
  module Aggregation

    def self.all
      Wonkavision::Plugins::Aggregation.all
    end

    def self.persistence
      @persistence
    end

    def self.included(handler)
      handler.class_eval do
        extend Plugins
        use Plugins::Aggregation
      end

      super
    end
  end
end
