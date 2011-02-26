module Wonkavision
  module Analytics
    def self.global_filters
      @global_filters ||= []
    end

    def apply_global_filters(filter_list=[])
      filters = filter_list.dup
      global_filters.each do |global|
        matches = filters.select{ |f|f.qualified_name = global.qualified_name }
        matches.blank? ? filters << global : matches.each{|f|f.assert_global(global)}
      end
    end
  end
end
