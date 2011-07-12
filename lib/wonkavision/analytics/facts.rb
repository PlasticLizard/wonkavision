require "set"

module Wonkavision
  module Analytics
    module Facts
      extend ActiveSupport::Concern
      include Wonkavision::EventHandler

      included do
        write_inheritable_attribute :facts_options, {}
        class_inheritable_reader :facts_options

        write_inheritable_attribute :aggregations, []
        class_inheritable_reader :aggregations
      end

      module ClassMethods

        def accept(event_path, options={}, &mapping_block)
          map(event_path, &mapping_block) if mapping_block
          handle event_path do
            accept_event(event_context.data, options)
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

        def transformation(name,&block)
          transformations << Wonkavision::Analytics::Transformation.new(name,&block)
        end

        def transformations
          facts_options[:transformations] ||= []
        end

        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ? store :
              Wonkavision::Analytics::Persistence::Store[new_store]

            raise "Could not find a storage type of #{new_store}" unless store

            store = store.new(self) if store.respond_to?(:new)

            facts_options[:store] = store
          else
            facts_options[:store]
          end
        end

        def facts_for(aggregation,filters,options={})
          raise "Please configure a storage for your Facts class before attempting to use #facts_for" unless store

          store.facts_for(aggregation,filters,options)
        end

        def purge!
          store.purge! if store
          self.aggregations.each do |agg|
            agg.purge!
          end
        end

      end

      module InstanceMethods
        def accept_event(event_data, options={})
          filter = self.class.filter
          action = options[:action] || :add
          unless filter.length > 0 && filter.detect{ |f|!!(f.call(event_data, action)) == false}
            send "#{action}_facts", event_data
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

        protected

        def process_transformations(event_data, action)
          self.class.transformations.each do |tx|
            [tx.apply(event_data)].flatten.compact.each do |msg|
              process_facts msg, action, tx.name
            end
          end
        end

        def store
          self.class.store
        end

        def process_facts(event_data, action, transformation = nil)
          self.class.aggregations.each do |aggregation| 
            if aggregation.transformation == transformation
              SplitByAggregation.process( {
                "action" => action,
                "aggregation" => aggregation.name,
                "data" => event_data
              } ) 
            end
          end
          process_transformations(event_data, action) unless transformation
        end

      end
    end
  end
end
