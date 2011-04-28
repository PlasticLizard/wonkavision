module Wonkavision

  module MessageMapper
    class Map < Hash
      include IndifferentAccess

      def initialize(context = nil)
        @write_missing = true
        @context_stack = []
        @context_stack.push(context) if context
      end

      def execute(context,map_block,options={})
        @write_missing = options[:write_missing].nil? ? true : options[:write_missing]
        @context_stack.push(context)
        instance_eval(&map_block)
        @context_stack.clear
        self
      end

      def context
        @context_stack[-1]
      end

      def ignore_missing!
        @write_missing = false
      end

      def write_missing!
        @write_missing = true
      end

      def from (context,&block)
        raise "No block ws provided to 'from'" unless block
        return if context.nil?

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
          ctx = extract_value_from_context(context,field_name)
        end
        if ctx && ctx != KeyMissing
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
          ctx = source[field_name]
        else
          field_name = source
          ctx = extract_value_from_context(context,field_name)
          ctx = nil if ctx == KeyMissing
        end
        result = []
        ctx = [ctx].compact.flatten
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
        args.add_options!(:format=>:dollars)
        float(*args)
      end
      alias dollar dollars

      def percent(*args)
        args.add_options!(:format=>:percent)
        float(*args)
      end
      alias percentage percent

      def yes_no(*args)
        args.add_options!(:format=>:yes_no)
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

      def time(*args)
        value(*args) do
          if kind_of?(Time)
            self
          elsif respond_to?(:to_time)
            to_time
          elsif (time_str=to_s) && time_str.length > 0
            begin
              Time.parse(time_str)
            rescue
              self
            end
          else
            self
          end
        end
      end

       def date(*args)
        value(*args) do
          if kind_of?(Date)
            self
          elsif respond_to?(:to_date)
            to_date
          elsif (date_str=to_s) && date_str.length > 0
            begin
              Date.parse(date_str)
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
      alias integer int

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

      def duration(*args, &block)
        opts = args.extract_options! || {}

        return nil if (opts.has_key?(:from) && !opts[:from])
        return nil if (opts.has_key?(:to) && !opts[:to])

        from = opts.delete(:from)
        to = opts.delete(:to)

        return nil unless from || to

        from ||= Time.now; to ||= Time.now

        unit = opts.delete(:in) || opts.delete(:unit) || :seconds

        duration = convert_seconds(to-from,unit)

        assignment = {args.shift => duration}
        args << assignment << opts

        value(*args, &block)

      end
      alias :elapsed :duration

      private

      def convert_seconds(duration, unit)
        duration /
        case unit.to_s
                         when "seconds" then 1
                         when "minutes" then 60
                         when "hours" then 60 * 60
                         when "days" then 60 * 60 * 24
                         when "weeks" then 60 * 60 * 24 * 7
                         when "months" then 60 * 60 * 24 * 30
                         when "years" then 60 * 60 * 24 *  365
                         else raise "Cannot convert duration to unknown time unit #{unit}"
                         end

      end

      def format_value(val,opts={})
        val = opts[:default] || opts[:default_value] if val.nil?
        return val if val.nil?

        format = opts[:format]
        format ||= :float if opts[:precision]
        format ? Wonkavision::StringFormatter.format(val,format,opts) : val
      end

      def extract_value_from_context(context,field_name,block=nil)
        value = nil
        key_missing = false
        if context.respond_to?(:[])
          value = context[field_name]
          if value.nil? && field_name
            value = context[field_name.to_sym] || context[field_name.to_s]
          end
          key_missing = !value && context.respond_to?(:keys) && 
	     context.keys.respond_to?("&") &&
             [] == context.keys & [field_name, field_name.to_sym, field_name.to_s]
        end

        if context.respond_to?(field_name.to_sym)
          value = context.instance_eval("self.#{field_name}")
          key_missing = false
        end unless value

	return KeyMissing if key_missing && !@write_missing

        value = value.instance_eval(&block) if block
        value
      end

      def set_value(field_name,val,opts={})
        if prefix = opts[:prefix]; field_name = "#{prefix}#{field_name}"; end
        if suffix = opts[:suffix]; field_name = "#{field_name}#{suffix}"; end
        unless val == KeyMissing
          self[field_name] = format_value(val,opts)
        end
      end

      #def add_options(args,new_options)
      #  opts = args.length > 1 ? args.extract_options! : {}
      #  opts.merge!(new_options)
      #  args << opts
      #  args
      #end
    end

    class KeyMissing
    end
  end
end
