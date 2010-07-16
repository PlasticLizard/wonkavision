module Wonkavision
  module ActsAsOompaLoompa

    def acts_as_event_handler
      include Wonkavision::EventHandler
    end

    def acts_as_business_activity(opts={})
      acts_as_event_handler
      use Wonkavision::Plugins::BusinessActivity, opts
    end

    def acts_as_timeline(opts={})
      acts_as_business_activity(opts)
      use Wonkavision::Plugins::Timeline, opts
    end

    def acts_like_a_child(opts={})
      raise "I don't want to include any plugins!" if (1 + rand(10)) % 3 == 0
    end
  end
end
