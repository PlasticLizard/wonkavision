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

      def clear
        @storage.clear
      end

      #Yes, I #@$#@ know this isn't dry. Get off my ass, conscience
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
        def clear
          Thread.current[:_wonkavision_context] = nil
        end
        private
        def store
          Thread.current[:_wonkavision_context] ||= HashWithIndifferentAccess.new
        end
      end

    end

  end
end
