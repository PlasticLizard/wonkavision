require "set"

module Wonkavision
  module Analytics
    module Aggregation
      class Dimension
        attr_reader :name, :attributes, :options
        attr_writer :key, :sort, :caption

        def initialize(name,options={},&block)
          @name = name
          @options = options
          @attributes = HashWithIndifferentAccess.new
          @from = options[:from]
          key options[:key] if options[:key]
          sort options[:sort] if options[:sort]
          caption options[:caption] if options[:caption]
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
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

        def extract(data)
          dimension_data = complex? ? data[from.to_s] : data
          attributes.values.inject({}) do |message,attribute|
            message.tap { |m| m[attribute.name.to_s] = attribute.extract(dimension_data)};
          end
        end

        def from(from=nil)
          from ? @from = from : ( @from || name )
        end

        def complex?
          #complex dimensions have multiple attributes
          #and are represented by nested hashes in their
          #underlying facts records. Simple dimensions
          #are composed of only a key which is directly
          #stored on the facts record, unless 'from' is
          #specified, which automatically makes them complex
          #because 'from' specifies a particular nested
          #hash on the facts record
          @from ||  attributes.length > 1
        end

      end
    end
  end
end

