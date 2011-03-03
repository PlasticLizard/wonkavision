module Wonkavision
  module Analytics
    class CellSet
      class Measure
        attr_reader :name, :data, :options, :default_component, :format
        def initialize(name,data,opts={})
          @name = name
          @data = data ? data.dup : {}
          @options = opts
          @default_component = options[:default_component] || options[:default_to] || :count
          @format = options[:format] || nil
        end

        def to_s
          formatted_value
        end

        def inspect
          value
        end

        def formatted_value
          format.blank? || value.blank? ? value.to_s :
            StringFormatter.format(value, format, options)
        end

        def value
          send(@default_component)
        end

        def empty?
          count.nil? || count < 1
        end

        def sum; empty? ? nil : @data["sum"]; end
        def sum2; empty? ? nil : @data["sum2"]; end
        def count; @data["count"]; end

        def mean; empty? ? nil : sum/count; end
        alias :average :mean

        def std_dev
          return Wonkavision::NaN unless count > 1
          Math.sqrt((sum2.to_f - ((sum.to_f * sum.to_f)/count.to_f)) / (count.to_f - 1))
        end

        def aggregate(new_data)
          @data["sum"] = @data["sum"].to_f + new_data["sum"].to_f
          @data["sum2"] = @data["sum2"].to_f + new_data["sum2"].to_f
          @data["count"] = @data["count"].to_i + new_data["count"].to_i
        end

        def method_missing(op,*args)
          value.send(op,*args)
        end

      end
    end
  end
end
