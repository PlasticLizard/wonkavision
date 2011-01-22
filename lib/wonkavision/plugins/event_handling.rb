module Wonkavision
  module Plugins
    module EventHandling

      def self.configure(handler,options)
        handler.write_inheritable_attribute :event_handler_options, {}
        handler.class_inheritable_reader :event_handler_options

        handler.write_inheritable_attribute :bindings, []
        handler.class_inheritable_reader :bindings

        handler.write_inheritable_attribute :maps, []
        handler.class_inheritable_reader :maps

      end

      module ClassMethods
        def options
          event_handler_options
        end

        def event_path(event_name)
          return event_name.to_s if Wonkavision.is_absolute_path(event_name) #don't mess with an absolute path
          Wonkavision.join(event_namespace,event_name)
        end

        def event_namespace(namespace=nil)
          return event_handler_options[:event_namespace] unless namespace
          event_handler_options[:event_namespace] = namespace
        end
        alias :namespace :event_namespace

        def map(condition = nil,&block)
          maps << [condition,block]
        end

        def handle(name,*args,&block)
          binding = create_binding(name,self,*args)
          binding.subscribe_to_events do |event_data,event_path|
            ctx = Wonkavision::EventContext.new(event_data,event_path,binding,block)
            handler = instantiate_handler(ctx)
            handler.instance_variable_set(:@wonkavision_event_context, ctx)
            handler.handle_event
          end
          bindings << binding
          binding
        end

        def instantiate_handler(event_context)
          self.new
        end

        def create_binding(name,handler,*args)
          Wonkavision::EventBinding.new(name,handler,*args)
        end

      end

      module InstanceMethods

        def handled?
          @wonkavision_event_handled ||= false
        end

        def handled=(handled)
          @wonkavision_event_handled = handled
        end

        def event_context
          @wonkavision_event_context
        end

        def handle_event
          ctx = @wonkavision_event_context
          ctx.data = map(ctx.data,ctx.path)
          handler = ctx.callback

          if handler && handler.respond_to?(:call) && handler.respond_to?(:arity)
              case handler.arity
              when 3 then handler.call(ctx.data,ctx.path,self)
              when 2 then handler.call(ctx.data,ctx.path)
              when 1 then handler.call(ctx.data)
              else instance_eval &handler
            end
          end
        end

        protected
        def map(data,path)
          self.class.maps.each do |map_def|
            condition = map_def[0]
            map_block = map_def[1]
            return Wonkavision::MessageMapper.execute(map_block,data) if map?(condition,data,path)
          end
          data.is_a?(Hash) ? data.dup : data
        end

        def map?(condition,data,path)
          return true unless condition && condition.to_s != 'all' && condition.to_s != '*'
          return path =~ condition if condition.is_a?(Regexp)
          if (condition.is_a?(Proc))
            return condition.call if condition.arity  <= 0
            return condition.call(path) if condition.arity == 1
            return condition.call(path,data)
          end
        end

        def broadcast(event_name, event)
        end

        def submit(event_name, event)
        end
      end

    end
  end
end
