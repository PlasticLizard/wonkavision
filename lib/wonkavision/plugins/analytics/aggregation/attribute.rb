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

        def extract(message)
          message[name.to_s]
        end

      end
    end
  end
end

