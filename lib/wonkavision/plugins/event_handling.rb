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
          binding = Wonkavision::EventBinding.new(name,self,*args)
          binding.subscribe_to_events do |event_data,event_path|
            event_data = map_data(event_data,event_path)
            if block_given?
              case block.arity
                when 2 then yield event_data,event_path
                when 1 then yield event_data
                else yield
              end
            end
          end
          bindings << binding
          binding
        end
        
        private

        def map_data(data,path)
          maps.each do |map_def|
            condition = map_def[0]
            map_block = map_def[1]
            return Wonkavision::MessageMapper.execute(map_block,data) if map?(condition,data,path)
          end
          data.is_a?(Hash) ? data.dup : data
        end

        def map?(condition,data,path)
          return true unless condition && condition.to_s != 'all'
          return path =~ condition if condition.is_a?(Regexp)
          if (condition.is_a?(Proc))
            return condition.call if condition.arity  <= 0
            return condition.call(path) if condition.arity == 1
            return condition.call(path,data)
          end
          #default behavior
          header.properties[:routing_key] == filter.to_s
        end
      end
      #Code here
    end
  end
end
