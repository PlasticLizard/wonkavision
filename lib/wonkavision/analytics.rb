require 'thread'

module Wonkavision
  module Analytics

    def self.context
      @context ||= Context.new
    end

    def self.default_store
      @default_store ||= Wonkavision::Analytics::Persistence::HashStore
    end

    def self.default_store=(store)
      if store.kind_of?(Wonkavision::Analytics::Persistence::Store)
        @default_store = store
      else
        @default_store = Wonkavision::Analytics::Persistence::Store[store.to_s]
      end
    end

    class Context
      def initialize(storage = nil)
        @storage = storage || ThreadContextStorage.new
      end    

      def global_filters
        @storage[:_wonkavision_global_filters] ||= []
      end

      def filter(criteria_hash = {})
        criteria_hash.each_pair do |filter, value|
          global_filter = filter.kind_of?(MemberFilter) ? filter : MemberFilter.new(filter)
          global_filter.value = value
          global_filters << global_filter
        end
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
