module Wonkavision

  module MessageMapper
    class Map < Hash
      include IndifferentAccess

      def initialize(context)
        @context_stack = []
        @context_stack.push(context)
        @formats = default_formats
      end

      def formats
        @formats
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

      def exec(map_name,exec_context=self.context)
        mapped = MessageMapper.execute(map_name,exec_context)
        self.merge!(mapped) if mapped
      end
      alias import exec
      alias apply exec

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
        set_value(field_name,child,options)
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
        set_value(field_name,result,options)
      end

      def string(*args)
        value(*args) {to_s}
      end

      def float(*args)
        value(*args){respond_to?(:to_f) ? to_f : self}
      end

      def dollars(*args)
        args = add_options(args,:format=>:dollars)
        float(*args)
      end
      alias dollar dollars

      def percent(*args)
        args = add_options(args,:format=>:percent)
        float(*args)
      end
      alias percentage percent

      def yes_no(*args)
        args = add_options(args,:format=>:yes_no)
        value(*args)
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
      alias time date

      def boolean(*args)
        value(*args) do
          %w(true yes).include?(to_s.downcase) ? true : false
        end
      end

      def int(*args)
        value(*args){respond_to?(:to_i) ? to_i : self}
      end

      def value(*args,&block)
        opts = args.length > 1 ? args.extract_options! : {}

        if (args.length == 1 && args[0].is_a?(Hash))
          args[0].each do |key,value|
            value = context.instance_eval(&value) if value.is_a?(Proc)
            value = value.instance_eval(&block) if block
            set_value(key,value,opts)
          end
        else
          args.each do |field_name|
            value = extract_value_from_context(context,field_name,block)
            set_value(field_name,value,opts)
          end
        end
      end
      alias integer int

      private
      def format_value(val,opts={})
        format = opts[:format]
        format ||= :float if opts[:precision]
        return val unless format
        formatter = formats[format] || format
        default_formatter = formats[:default]

        formatter.respond_to?(:call) ? formatter.call(val,format,opts) : default_formatter.call(val,formatter,opts)
      end

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

      def set_value(field_name,val,opts={})
        if prefix = opts[:prefix]; field_name = "#{prefix}#{field_name}"; end
        if suffix = opts[:suffix]; field_name = "#{field_name}#{suffix}"; end
        self[field_name] = format_value(val,opts)
      end

      def default_formats
        HashWithIndifferentAccess.new(
                :default=>lambda {|v,f,opts| v.respond_to?(:strftime) ? v.strftime(f) : f % v } ,
                :float =>lambda {|v,f,opts| precision_format(opts) % v },
                :dollars=>lambda {|v,f,opts| "$#{precision_format(opts,2)}" % v},
                :percent=>lambda {|v,f,opts| "#{precision_format(opts,1)}%%" % v},
                :yes_no=>lambda {|v,f,opts| v ? "Yes" : "No"}
        )
      end

      def precision_format(opts,default_precision=nil)
        precision = opts[:precision] || default_precision
        "%#{precision ? "." + precision.to_s : default_precision}f"
      end

      def add_options(args,new_options)
        opts = args.length > 1 ? args.extract_options! : {}
        opts.merge!(new_options)
        args << opts
        args
      end
    end
  end
end
