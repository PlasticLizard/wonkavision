module Wonkavision

  module MessageMapper
    class Map < Hash
      include IndifferentAccess

      def initialize(context)
        @context_stack = []
        @context_stack.push(context)
      end

      def context
        @context_stack[-1]
      end

      def from (context,&block)
        raise "No block ws provided to 'from'" unless block
        @context_stack.push(context)
        instance_eval(&block)
        @context_stack.pop
      end

      def exec(map_name)
        mapped = MessageMapper.execute(map_name,context)
        self.merge!(mapped) if mapped
      end
      alias import exec

      def child(source,options={},&block)
        raise "Neither a block nor a map_name were provided to 'map'" unless (block || options.keys.include?(:map_name))
        if (source.is_a?(Hash))
          field_name = source.keys[0]
          ctx = source[field_name]
        else
          field_name = source
          ctx = context.instance_eval("self.#{field_name}")
        end
        if ctx
          if (map_name = options.delete(:map_name))
            child = MessageMapper.execute(map_name,ctx)
          else
            child = Map.new(ctx)
            child.instance_eval(&block)
          end
        else
          child = {}
        end
        self[field_name] = child
      end

      def array(source,options={},&block)
        if (source.is_a?(Hash))
          field_name = source.keys[0]
          ctx = source.keys[1]
        else
          field_name = source
          ctx = extract_value_from_context(context,field_name)
        end
        result = []
        map_name = options.delete(:map_name)
        ctx.each do |item|
          if (map_name)
            child = MessageMapper.execute(map_name,item)
          else
            child = Map.new(item)
            child.instance_eval(&block)
          end
          result << child
        end
        self[field_name] = result
      end

      def string(*args)
        value(*args) {to_s}
      end

      def float(*args)
        value(*args){respond_to?(:to_f) ? to_f : self}
      end

      def iso8601(*args)
        value(*args) do
          if respond_to?(:strftime)
            strftime("%Y-%m-%dT%H:%M:%S")
          elsif respond_to?(:ToString)
            ToString("yyyy-MM-ddTHH:mm:ss")
          else
            self
          end
        end
      end

      def date(*args)
        value(*args) do
          if kind_of?(Time) || kind_of?(Date)
            self
          elsif respond_to?(:to_time)
            to_time
          elsif respond_to?(:to_date)
            to_date
          elsif (date_str=to_s) && date_str.length > 0
            begin
              Time.parse(date_str)
            rescue
              self
            end
          else
            self
          end
        end
      end

      def boolean(*args)
        value(*args) do
          %w(true yes).include?(to_s.downcase) ? true : false
        end
      end

      def int(*args)
        value(*args){respond_to?(:to_i) ? to_i : self}
      end

      def value(*args,&block)
        if (args.length == 1 && args[0].is_a?(Hash))
          args[0].each do |key,value|
            value = context.instance_eval(&value) if value.is_a?(Proc)
            value = value.instance_eval(&block) if block
            self[key] = value
          end
        else
          args.each do |field_name|
            value = extract_value_from_context(context,field_name,block)
            self[field_name] = value
          end
        end
      end
      alias integer int

      private
      def extract_value_from_context(context,field_name,block=nil)
        if context.respond_to?(field_name.to_sym)
          value = context.instance_eval("self.#{field_name}")
        elsif context.respond_to?(:[])
          value = context[field_name]
        else
          value = nil
        end
        value = value.instance_eval(&block) if block
        value
      end
    end
  end
end
