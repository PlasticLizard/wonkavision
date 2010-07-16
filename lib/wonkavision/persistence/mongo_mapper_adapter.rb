module Wonkavision
  module Persistence
    module MongoMapperAdapter

      def self.included(model)
        model.plugin Wonkavision::Persistence::MongoMapperAdapter
      end

      module ClassMethods
        include Wonkavision::ActsAsOompaLoompa        

        def define_document_key(key_name,key_type,options={})
          key(key_name, key_type, options) unless keys[key_name]
        end

        def update_activity(activity,event_data)
          activity.assign(event_data)
          :updated
        end

        def find_activity_instance(correlation_field_name,correlation_id)
          self.send("find_or_create_by_#{correlation_field_name}",correlation_id)
        end
      end

    end

  end
end

if defined?(::MongoMapper::Document)
  MongoMapper::Document.append_inclusions(Wonkavision::Persistence::MongoMapperAdapter)
end