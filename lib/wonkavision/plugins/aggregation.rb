module Wonkavision
  module Plugins
    module Aggregation

      def self.all
        @@all ||= {}
      end

      def self.configure(aggregation,options={})
        aggregation.write_inheritable_attribute :aggregation_options, options
        aggregation.class_inheritable_reader :aggregation_options

        aggregation.write_inheritable_attribute( :aggregation_spec,
                                                 AggregationSpec.new(aggregation.name) )
        aggregation.class_inheritable_reader :aggregation_spec

        Aggregation.all[aggregation.name] = aggregation
      end

      module ClassMethods
        def [](attributes)
          @instances ||= {}
          @instances[attributes] ||= self.new(attributes)
        end

        def method_missing(m,*args)
          aggregation_spec.respond_to?(m) ? aggregation_spec.send(m,*args) : super
        end
      end

      module InstanceMethods
        attr_reader :attributes

        def initialize(attributes)
          @attributes = attributes
        end

        def add(measures)
          update(measures, :add)
        end

        def reject(measures)
          update(measures, :reject)
        end

        protected
        def update(measures, method)
          measures.keys.each { |measure| update_measure(measure.to_s,measures[measure], method) }
        end

        def update_measure(measure_name, measure_value, update_method)
          measure = get_measure(measure_name)
          measure.send(update_method, measure_value)
        end

        def get_measure(measure_name)
          @measures ||= {}
          @measures[measure_name] ||= Measure.new(measure_name)
        end

      end

    end
  end
end
