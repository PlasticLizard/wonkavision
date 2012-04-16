module Wonkavision
  module Analytics
    module Aggregation
      extend ActiveSupport::Concern

      def self.all
        @@all ||= {}
      end

      included do
        class_attribute :aggregation_options, :instance_write => false
        self.aggregation_options = {}

        class_attribute :aggregation_spec, :instance_writer => false
        self.aggregation_spec = AggregationSpec.new(name)

        class_attribute :snapshots, :instance_write => false
        self.snapshots = {}

        Aggregation.all[name] = self
      end

      module ClassMethods
        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ?
              store.store_name : new_store
            
            
            store = store.new(self) if store.respond_to?(:new)

            aggregation_options[:store] = store
          else
            store_name = aggregation_options[:store] || :default
            klass = Wonkavision::Analytics::Persistence::Store[store_name]
            raise "Wonkavision could not find a store of type #{store_name}" unless klass
            @store ||= klass.new(self)
          end
        end


        def [](dimensions, snapshot = nil)
          key = [dimension_names(dimensions),dimension_keys(dimensions, snapshot)]
          @instances ||= HashWithIndifferentAccess.new
          @instances[key] ||= self.new(dimensions, snapshot)
        end

        def aggregates(facts_class = nil)
          return aggregation_options[:facts_class] unless facts_class

          facts_class.aggregations << self
          aggregation_options[:facts_class] = facts_class
        end
        alias facts aggregates

        def snapshot(name, &block)
          raise "This aggregation is not associated with any Facts, so no snapshot definition can be found" unless facts
          snap = facts.snapshots[name.to_sym]
          raise "#{name} is not a valid snapshot on #{facts.name}" unless snap
          
          snap_spec = SnapshotBinding.new(name, self, snap)
          snap_spec.dimension snap.key_name do |dim|
            dim.from snap.key_name
            dim.key snap.key
          end

          if block_given?
            block.arity == 1 ? block.call(snap_spec) : 
                               snap_spec.instance_eval(&block)
          end
          snapshots[name] = snap_spec
        end

        def find_dimension(dimension_name)
          unless dim = dimensions[dimension_name]
            snapshots.values.each do |ss|
              break if dim = ss.dimensions[dimension_name]
            end
          end
          dim
        end

        def find_measure(measure_name)
          unless measure = measures[measure_name]
            snapshots.values.each do |ss|
              break if measure = ss.measures[measure_name]
            end
          end
          measure
        end

        def dimensions(snapshot = nil)
          snapshot ? aggregation_spec.dimensions.merge(snapshots[snapshot.to_sym].dimensions) : aggregation_spec.dimensions
        end

        def measures(snapshot = nil)
          snapshot ? aggregation_spec.measures.merge(snapshots[snapshot.to_sym].measures) : aggregation_spec.measures
        end

        def dimension_names(dimensions)
          dimensions.keys.sort
        end

        def dimension_keys(dimensions, snapshot = nil)
          dims = self.dimensions
          dims = dims.merge(snapshot.dimensions) if snapshot
          dimension_names(dimensions).map do |dim|
            dimensions[dim][dims[dim].key.to_s]
          end
        end

        def query(options={},&block)
          raise "Aggregation#query is not valid unless a store has been configured" unless store
          query = Wonkavision::Analytics::Query.new
          query.instance_eval(&block) if block
          query.validate!

          return query if options[:defer]

          execute_query(query)
        end

        def execute_query(query)
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

        def purge!(purge_snapshots = false)
          criteria = purge_snapshots ? {} : {"snapshot" => {"$exists"=>false}}
          store.purge!(criteria)
        end

        def aggregate!(facts, action, snapshot = nil)
          SplitByAggregation.process(self, action, facts, snapshot)
        end
      end

      module InstanceMethods
        attr_reader :dimensions, :measures, :snapshot

        def initialize(dimensions, snapshot = nil)
          @dimensions = dimensions
          @snapshot = snapshot
        end

        def add(measures, snapshot = nil)
          update(measures, :add)
        end

        def reject(measures, snapshot = nil)
          update(measures, :reject)
        end

        def dimension_names
          @dimension_names ||= self.class.dimension_names(@dimensions)
        end

        def dimension_keys
          @dimension_keys ||= self.class.dimension_keys(@dimensions, @snapshot)
        end

        protected
        def update(measures, method)
          aggregation = {
            :dimension_keys => dimension_keys,
            :dimension_names => dimension_names,
            :measures => {},
            :dimensions => @dimensions
          }
          aggregation[:snapshot] = @snapshot.name if @snapshot

          measures.keys.each do |measure|
            if val = measures[measure]
              aggregation[:measures].merge! measure_changes_for(measure.to_s,
                                                                val,
                                                                method)
            end

          end
          self.class.store.update_aggregation(aggregation)
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
