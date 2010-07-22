module Wonkavision

  module EventHandler

    def self.included(handler)
      handler.class_eval do
        extend Plugins
        use Plugins::EventHandling
        use Plugins::Callbacks
      end

      super
    end
  end
end
