module Wonkavision
  module Plugins
    module BusinessActivity

      def self.all
        @@all ||= []
      end


      def self.configure(activity,options={})
        activity.write_inheritable_attribute :business_activity_options, {}
        activity.class_inheritable_reader :business_activity_options

        activity.write_inheritable_attribute :correlation_ids, []
        activity.class_inheritable_reader :correlation_ids

        BusinessActivity.all << activity
      end

      def self.normalize_correlation_ids(*args)
        model_field,event_field = if args.length == 1 then
                                    case args[0]
                                      when Hash then [args[0][:model], args[0][:event] || args[0][:model]]
                                      else [args[0],args[0]]
                                    end
                                  else
                                    [args[0],args[1] || args[0]]
                                  end
        {:model=>model_field,:event=>event_field}
      end

      module ClassMethods
        def instantiate_handler(event_context)
          correlation = event_context.binding.correlation
          event_id = correlation ? (correlation[:event] || event_correlation_id_key) : event_correlation_id_key
          model_id = correlation ? (correlation[:model] || correlation_id_field) : correlation_id_field

          correlation_id = event_context.data[event_id.to_s]
          find_activity_instance(model_id,correlation_id)
        end

        def event(name,*args,&block)
          handle(name,args) do
            ctx = @wonkavision_event_context
            result = :ok
            if (block_given?)
              result = case block.arity
                         when 3 then yield ctx.data,ctx.path,self
                         when 2 then yield ctx.data, ctx.path
                         when 1 then yield ctx.data
                         else instance_eval &block
                       end
            end
            unless result == :handled
              result = self.class.update_activity(self,ctx.data) unless result == :updated
              save!
            end
            result
          end
        end

        def correlate_by(*args)
          return {:model=>correlation_id_field, :event=>event_correlation_id_key} if args.blank?

          correlation = BusinessActivity.normalize_correlation_ids(*args)

          business_activity_options[:correlation_id_field] = correlation[:model]
          business_activity_options[:event_correlation_id_key] = correlation[:event]

          define_document_key correlation_id_field, String, :index=>true
          correlation_ids << correlation
        end

        def create_binding(name,handler,*args)
          Wonkavision::Plugins::BusinessActivity::EventBinding.new(name,handler,*args)
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