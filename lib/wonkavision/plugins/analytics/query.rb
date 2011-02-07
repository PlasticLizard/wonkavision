module Wonkavision
  module Analytics
    class Query
      attr_reader :axes, :filters

      def initialize()
        @axes = []
        @slicer = Set.new
        @filters = []
      end

      def select(*dimensions)
        options = dimensions.extract_options!
        axis = options[:axis] || options[:on]
        axis_ordinal = self.class.axis_ordinal(axis)
        @axes[axis_ordinal] = dimensions
        self
      end

      def where(criteria_hash = {})
        criteria_hash.each_pair do |filter,value|
          member_filter = filter.kind_of?(MemberFilter) ? filter :
            MemberFilter.new(filter)
          member_filter.value = value
          @filters << member_filter
          @slicer << member_filter.name if member_filter.dimension?
        end
        self
      end

      def slicer
        @slicer.to_a
      end

      def referenced_dimensions
        ( [] + selected_dimensions + slicer ).uniq.compact
      end

      def selected_dimensions
        dimensions = []
        axes.each { |dims|dimensions.concat(dims) unless dims.blank? }
        dimensions.uniq.compact
      end

      def all_dimensions?
        axes.empty?
      end

      def matches_filter?(aggregation, tuple)
        return true if all_filters_applied?
        !( filters.detect{ |filter| !filter.matches(aggregation, tuple) } )
      end

      def all_filters_applied?
        @all_filters_applied ||= !(filters.detect{ |filter| !filter.applied? })
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
