require 'thread'

module Wonkavision
  module Analytics

    def self.context
      @context ||= Context.new
    end

    class Context
      def initialize(storage = nil)
        @storage = storage || StaticContextStorage.new
      end

      def global_filters
        @storage[:_wonkavision_global_filters] ||= []
      end

      class StaticContextStorage
        def [](key)
          store[key]
        end
        def []=(key,value)
          store[key] = value
        end

        private
        def store
          @@storage ||= HashWithIndifferentAccess.new
        end
      end

    end

  end
end
