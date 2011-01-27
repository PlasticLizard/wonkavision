require "set"

module Wonkavision
  module Plugins
    module Aggregation
      class Attribute
        attr_reader :name, :options

        def initialize(name,options={})
          @name = name
          @options = options
        end

      end
    end
  end
end

