require "set"

module Wonkavision
  module Analytics
    module Facts
      extend ActiveSupport::Concern
      include Wonkavision::EventHandler

      included do
        class_attribute :facts_options, :instance_writer => false
        self.facts_options = {}

        class_attribute :aggregations, :instance_writer => false
        self.aggregations = []

        class_attribute :snapshots, :instance_writer => false
        self.snapshots = {}
      end

      module ClassMethods

        def accept(event_path, options={}, &mapping_block)
          map(event_path, &mapping_block) if mapping_block
          handle event_path do
            facts = self.class.apply_dynamic(event_context.data, :context_time => Time.now.utc)
            accept_event facts, options
          end
        end

        def snapshot(name, options={}, &blk)
          snap = Snapshot.new(self, name, options, &blk)
          snapshots[name] = snap
          handle snap.event_name do
            accept_event event_context.data, :action => :snapshot,
                                             :snapshot => snap
          end
        end

        def record_id(new_record_id=nil)
          if new_record_id
            facts_options[:record_id] = new_record_id
          else
            facts_options[:record_id] ||= "id"
          end
        end

        def filter(&block)
          if block
            (facts_options[:filters] ||= []) << block
          else
            (facts_options[:filters] ||= [])
          end
        end

        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ?
              store.store_name : new_store
            
            facts_options[:store] = store
          else
            store_name = facts_options[:store] || :default
            if store_name.to_s != "none"
              klass = Wonkavision::Analytics::Persistence::Store[store_name]
              raise "Wonkavision could not find a store of type #{store_name}" unless klass
              @store ||= klass.new(self)
            end
          end
        end

        def dynamic(map_name = nil, &mapping_block)
          unless map_name || block_given?
            facts_options[:dynamic_map]
          else
            facts_options[:dynamic_map] = map_name || mapping_block
          end
        end

        def facts_for(aggregation,filters,options={})
          raise "Please configure a storage for your Facts class before attempting to use #facts_for" unless store
          store.facts_for(aggregation,filters,options)
        end

        def purge!(purge_snapshots = false)
          store.purge! if store
          self.aggregations.each do |agg|
            agg.purge!(purge_snapshots)
          end
        end

        def apply_dynamic(facts, options={})
          if map = dynamic
            facts.merge Wonkavision::MessageMapper.execute(map, facts, options)
          else
            facts
          end
        end

        def update_dynamic(facts, options={})
          facts = apply_dynamic(facts, :context_time => Time.now.utc)
          facts[record_id.to_s] = facts.delete("_id")
          self.new.accept_event facts, options.merge(:action => :update)
        end

      end

      module InstanceMethods

        def accept_event(event_data, options = {})
          filter = self.class.filter
          action = options[:action] || :add
          snapshot = options[:snapshot]
          unless filter.length > 0 && filter.detect{ |f|!!(f.call(event_data, action)) == false}
            snapshot ? snapshot_facts(event_data, snapshot) : 
                       send( "#{action}_facts", event_data )
          end
        end

        def update_facts(data)
          raise "A persistent store must be configured in order to update facts" unless store

          previous_facts, current_facts = store.update_facts(data)
          unless previous_facts == current_facts
            process_facts previous_facts, "reject" unless previous_facts.blank?
            process_facts current_facts, "add" unless current_facts.blank?
          end
        end

        def add_facts(data)
          current_facts = store ? store.add_facts(data) : data
          if current_facts
            process_facts current_facts, "add"
          end
        end

        def reject_facts(data)
          previous_facts = store ? store.remove_facts(data) : data
          if previous_facts
            process_facts previous_facts, "reject"
          end
        end

        def snapshot_facts(snapshot_data, snapshot)
          raise "A snapshot must be passed in the options to call snapshot_facts" unless snapshot
          process_facts snapshot_data, "add", snapshot
        end
             
        protected

        def store
          self.class.store
        end

        def process_facts(event_data, action, snapshot = nil)
          self.class.aggregations.each do |aggregation|
            if snapshot.nil? || aggregation.snapshots[snapshot.name]
              aggregation.aggregate!(event_data, action, snapshot)
            end
          end
        end       

      end
    end
  end
end
