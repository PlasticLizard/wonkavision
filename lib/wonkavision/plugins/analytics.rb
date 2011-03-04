require 'thread'

module Wonkavision
  module Analytics

    def self.context
      @context ||= Context.new
    end

    class Context
      def initialize(storage = nil)
        @storage = storage || ThreadContextStorage.new
      end

      def global_filters
        @storage[:_wonkavision_global_filters] ||= []
      end

      class ThreadContextStorage
        def [](key)
          store[key]
        end
        def []=(key,value)
          store[key] = value
        end

        private
        def store
          Thread.current[:_wonkavision_context] ||= HashWithIndifferentAccess.new
        end
      end

    end

  end
end
