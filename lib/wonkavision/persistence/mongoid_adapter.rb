module Wonkavision
  module Mongoid
    module Activity

      def self.included(model)
        model.send(:include,::Mongoid::Document)
        model.extend(ClassMethods)
      end

      module ClassMethods
        include Wonkavision::ActsAsOompaLoompa

        def define_document_key(key_name,key_type,options={})
          options[:type] = key_type
          field(key_name,  options) unless fields[key_name]
        end

        def update_activity(activity,event_data)
          activity.write_attributes(event_data)
          :updated
        end

        def find_activity_instance(correlation_field_name,correlation_id)
          self.find_or_create_by({correlation_field_name=>correlation_id})
        end
      end

    end

  end
end

