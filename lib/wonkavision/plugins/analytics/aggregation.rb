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
        def [](dimensions)
          @instances ||= HashWithIndifferentAccess.new
          @instances[dimensions] ||= self.new(dimensions)
        end

        def dimension_names(dimensions)
          dimensions.keys.sort
        end

        def dimension_keys(dimensions)
          dimension_names(dimensions).map do |dim|
            dimensions[dim.to_s][self.dimensions[dim].key.to_s]
          end
        end

        def query(query)
          raise NotImpelementedError, "#query is not implemented for in-memory aggregations"
        end

        def method_missing(m,*args)
          aggregation_spec.respond_to?(m) ? aggregation_spec.send(m,*args) : super
        end
      end

      module InstanceMethods
        attr_reader :dimensions, :measures

        def initialize(dimensions)
          @dimensions = dimensions
        end

        def add(measures)
          update(measures, :add)
        end

        def reject(measures)
          update(measures, :reject)
        end

        def dimension_names
          @dimension_names ||= self.class.dimension_names(@dimensions)
        end

        def dimension_keys
          @dimension_keys ||= self.class.dimension_keys(@dimensions)
        end

        protected
        def update(measures, method)
          measures.keys.each { |measure| update_measure(measure.to_s,measures[measure], method) }
          self
        end

        def update_measure(measure_name, measure_value, update_method)
          measure = get_measure(measure_name)
          measure.send(update_method, measure_value)
        end

        def get_measure(measure_name)
          @measures ||= HashWithIndifferentAccess.new
          @measures[measure_name] ||= Measure.new(measure_name)
        end

      end

    end
  end
end
