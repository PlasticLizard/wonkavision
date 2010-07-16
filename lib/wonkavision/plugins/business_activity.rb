module Wonkavision
  module Plugins
    module BusinessActivity

      def self.configure(activity,options={})
        activity.write_inheritable_attribute :business_activity_options, {}
        activity.class_inheritable_reader :business_activity_options
      end

      module ClassMethods

        def event(name,*args,&block)
          handle(name,args) do |data,path|
            activity = find_activity(data)
            result = :ok
            if (block_given?)
              result = case block.arity
                         when 3 then yield activity,data,path
                         when 2 then yield activity,data
                         when 1 then yield activity
                         else yield
                       end
            end
            unless result == :handled
              result = update_activity(activity,data) unless result == :updated
              activity.save!
            end
            result
          end
        end

        def correlate_by(*args)
          return {:model=>correlation_id_field, :event=>event_correlation_id_key} if args.blank?
          model_field,event_field = if args.length == 1 then
                                      case args[0]
                                        when Hash then [args[0][:model], args[0][:event] || args[0][:model]]
                                        else [args[0],args[0]]
                                      end
                                    else
                                      [args[0],args[1] || args[0]]
                                    end

          business_activity_options[:correlation_id_field] = model_field
          business_activity_options[:event_correlation_id_key] = event_field

          define_document_key correlation_id_field, String, :index=>true
        end

        def find_activity(event_data)
          correlation_id = event_data[event_correlation_id_key.to_s]
          find_activity_instance(correlation_id_field,correlation_id)
        end

      end

      module Fields

        def correlation_id_field
          business_activity_options[:correlation_id_field] ||= "id"
        end

        def event_correlation_id_key
          business_activity_options[:event_correlation_id_key] || correlation_id_field
        end

      end
    end
  end
end