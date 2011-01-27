require "set"

module Wonkavision
  module Plugins
    module Aggregation
      class Dimension
        attr_reader :name, :attributes, :options
        attr_writer :key, :sort, :caption

        def initialize(name,options={},&block)
          @name = name
          @options = options
          @attributes = HashWithIndifferentAccess.new
          key options[:key] if options[:key]
          sort options[:sort] if options[:sort]
          caption options[:caption] if options[:caption]
          self.instance_eval(&block) if block
          key name unless key
        end

        def attribute(*attribute_list)
          raise "No attribute names were specified when calling '#attribute'" if
            attribute_list.blank?

          options = attribute_list.extract_options! || {}
          attribute_list.flatten.each do |attribute|
            @attributes[attribute] = Attribute.new(attribute,options)
          end
        end

        def sort(sort_key = nil, options={})
          return @sort || @key unless sort_key
          attribute(sort_key, options) unless attributes[sort_key]
          @sort = sort_key
        end
        alias :sort_by :sort

        def caption(caption_key=nil, options={})
          return @caption || @key unless caption_key
          attribute(caption_key, options) unless attributes[caption_key]
          @caption = caption_key
        end

        def key(key=nil, options={})
          return @key unless key
          attribute(key, options) unless attributes[key]
          @key = key
        end

      end
    end
  end
end

