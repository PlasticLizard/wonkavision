require "set"

module Wonkavision
  module Plugins
    module Aggregation
      class Dimension
        attr_reader :name, :attributes
        attr_writer :sort, :caption

        def initialize(name,options={},&block)
          @name = name
          @options = options
          @key = options[:key] || name
          @sort = options[:sort]
          @caption = options[:caption]
          @attributes = Set.new
          self.instance_eval(&block) if block
        end

        def attribute(*attribute_list)
          return @attributes if attribute_list.blank?
          @attributes << attribute_list.flatten
        end

        def sort(sort_key = nil)
          return @sort unless sort_key
          @sort = sort_key
        end
        alias :sort_by :sort

        def caption(caption_key=nil)
          return @caption unless caption_key
          @caption = caption_key
        end

        def key(key=nil)
          return @key unless key
          @key = key
        end

      end
    end
  end
end

