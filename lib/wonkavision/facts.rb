module Wonkavision
  module Facts

  def self.persistence
      @persistence
    end

    #current only supports :mongo
    def self.persistence=(backend)
      case backend
      when :mongo then require File.dirname(__FILE__) + "/plugins/analytics/mongo"
      else
        raise "#{backend} is not a supported back end for Wonkavision analytics"
      end
      @persistence = backend
    end

    def self.included(facts)
      facts.class_eval do
        extend Plugins
        use Plugins::EventHandling
        use Plugins::Callbacks
        use Plugins::Facts
      end
    end
  end
end
