module Wonkavision
  module Analytics
    class Query
      attr_reader :axes

      def initialize()
        @axes = []
      end

      def select(*dimensions)
        options = dimensions.extract_options!
        axis = options[:axis] || options[:on]
        axis_ordinal = self.class.axis_ordinal(axis)
          @axes[axis_ordinal] = dimensions
      end

      def selected_dimensions
        validate!
        dimensions = []
        axes.each { |dims|dimensions.concat(dims) unless dims.blank? }
        dimensions.uniq.compact.sort{ |a,b| a.to_s <=> b.to_s }
      end

      def all_dimensions?
        validate!
        axes.empty?
      end

      def validate!
        axes.each_with_index{|axis,index|raise "Axes must be selected from in consecutive order and contain at least one dimension. Axis #{index} is blank." if axis.blank?}
      end

      def self.axis_ordinal(axis_def)
        case axis_def.to_s.strip.downcase.to_s
        when "columns" then 0
        when "rows" then 1
        when "pages" then 2
        when "chapters" then 3
        when "sections" then 4
        else axis_def.to_i
        end
      end

    end
  end
end
