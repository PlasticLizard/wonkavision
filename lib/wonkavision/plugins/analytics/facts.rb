require "set"

module Wonkavision
  module Plugins
    module Facts

      def self.configure(facts, options ={})
        facts.write_inheritable_attribute :facts_options, options
        facts.class_inheritable_reader :facts_options

        facts.write_inheritable_attribute :aggregations, []
        facts.class_inheritable_reader :aggregations
      end

      module ClassMethods

        def output_event_path(new_path=nil)
          if new_path
            facts_options[:output_event_path] = new_path
          else
            facts_options[:output_event_path] ||=
              Wonkavision.join('wv','analytics','facts','updated')
          end
        end

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

        def store(new_store=nil)
          if new_store
            facts_options[:store] = new_store
          else
            facts_options[:store]
          end
        end
      end

      module InstanceMethods
        def accept_event(event_data, options={})
          action = options[:action] || :add
          send "#{action}_facts", event_data
        end

        def update_facts(data)
          raise "A persistent store must be configured in order to update facts" unless store

          previous_facts, current_facts = store.update_facts(data)
          unless previous_facts == current_facts
            process_facts previous_facts, "reject" if previous_facts
            process_facts current_facts, "add" if current_facts
          end
        end

        def add_facts(data)
          current_facts = store ? store.add_facts(data) : data
          process_facts current_facts, "add" if current_facts
        end

        def reject_facts(data)
          previous_facts = store ? store.remove_facts(data) : data
          process_facts previous_facts, "reject" if previous_facts
        end

        protected

        def store
          self.class.store
        end

       #It is unnecessary to accept multiple actions - this should be removed
        def process_facts(event_data, *actions)
          actions.each do |action|
            self.class.aggregations.each do |aggregation|
              submit self.class.output_event_path, {
                "action" => action,
                "aggregation" => aggregation.name,
                "data" => event_data
              }
            end
          end
        end

      end
    end
  end
end
