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
        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ? store :
              Wonkavision::Analytics::Persistence::Store[new_store]

            raise "Could not find a storage type of #{new_store}" unless store

            store = store.new(self) if store.respond_to?(:new)

            aggregation_options[:store] = store
          else
            aggregation_options[:store]
          end
        end


        def [](dimensions)
          key = [dimension_names(dimensions),dimension_keys(dimensions)]
          @instances ||= HashWithIndifferentAccess.new
          @instances[key] ||= self.new(dimensions)
        end

        def aggregates(facts_class = nil)
          return aggregation_options[:facts_class] unless facts_class

          facts_class.aggregations << self
          aggregation_options[:facts_class] = facts_class
        end
        alias facts aggregates

        def dimension_names(dimensions)
          dimensions.keys.sort
        end

        def dimension_keys(dimensions)
          dimension_names(dimensions).map do |dim|
            dimensions[dim][self.dimensions[dim].key.to_s]
          end
        end

        def query(options={},&block)
          raise "Aggregation#query is not valid unless a store has been configured" unless store
          query = Wonkavision::Analytics::Query.new
          query.instance_eval(&block) if block
          query.validate!

          return query if options[:defer]

          tuples = store.execute_query(query)

          Wonkavision::Analytics::CellSet.new( self,
                                               query,
                                               tuples )
        end

        def facts_for(filters, options={})
          raise "Cannot provide underlying facts. Did you forget to associate your aggregation with a Facts class using 'aggregates' ? " unless aggregates

          aggregates.facts_for(self, filters, options)
        end


        def method_missing(m,*args,&block)
          aggregation_spec.respond_to?(m) ? aggregation_spec.send(m,*args,&block) : super
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
          aggregation = {
            :dimension_keys => dimension_keys,
            :dimension_names => dimension_names,
            :measures => {},
            :dimensions => @dimensions
          }

          measures.keys.each do |measure|
            if val = measures[measure]
              aggregation[:measures].merge! measure_changes_for(measure.to_s,
                                                                val,
                                                                method)
            end

          end
          self.class.store.update_aggregation(aggregation)
          self
        end

        def measure_changes_for(measure_name, measure_value, update_method)
          sign = update_method.to_s == "reject" ? -1 : 1
          {
            "measures.#{measure_name}.count" => 1 * sign,
            "measures.#{measure_name}.sum" => measure_value * sign,
            "measures.#{measure_name}.sum2" => (measure_value * measure_value) * sign
          }
        end

      end

    end
  end
end
