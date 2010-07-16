module Wonkavision

  module EventHandler

    def self.included(handler)
      handler.class_eval do
        extend Plugins
        use Plugins::EventHandling
      end

      super
    end
  end
end
