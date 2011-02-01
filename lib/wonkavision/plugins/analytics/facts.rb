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
      end

      module InstanceMethods
        def accept_event(event_data,options={})
          action = options[:action] || :add
          send "#{action}_facts", event_data
        end

        def add_facts(current_event_data)
          process_facts current_event_data, "add"
        end

        def reject_facts(previous_fact_data)
          process_facts previous_fact_data, "reject"
        end

        protected
        def process_facts(event_data,*actions)
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
