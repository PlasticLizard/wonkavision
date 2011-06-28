# encoding: UTF-8
# This concept is torn from the chest cavity of
# jnunemakers plucky library (https://github.com/jnunemaker/plucky/blob/master/lib/plucky/extensions/symbol.rb)
module Wonkavision
  module Extensions
    module Symbol

      [:key, :caption, :sort].each do |dimension_attribute|
        define_method(dimension_attribute) do
          _filter(dimension_attribute, :member_type=>:dimension)
        end unless method_defined?(dimension_attribute)
      end

      [:sum, :sum2, :count].each do |measure_attribute|
        define_method(measure_attribute) do
          _filter(measure_attribute, :member_type=>:measure)
        end unless method_defined?(measure_attribute)
      end

      # def[](name)
      #   _filter(name)
      # end

      def method_missing(name,*args)
        _filter(name) if _is_member_filter?
      end

      private
      def _member_type
        self == :measures ? :measure : :dimension
      end

      def _is_member_filter?
        [:dimensions,:measures].include?(self)
      end

       def _filter(name, options={})
        options[:member_type] ||= _member_type
        if !_is_member_filter?
          member_name = self
          options[:attribute_name] = name
        else
          member_name = name
        end
        Wonkavision::Analytics::MemberFilter.new(member_name,options)
      end

    end
  end
end


class Symbol
  include Wonkavision::Extensions::Symbol
end
