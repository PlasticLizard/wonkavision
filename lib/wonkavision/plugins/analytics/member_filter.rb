module Wonkavision
  module Analytics
    class MemberFilter
      include Comparable

      attr_reader :name, :operator, :member_type
      attr_accessor :value

      def initialize(member_name, options={})
        @name = member_name
        @attribute_name = options[:attribute_name]
        @operator = options[:operator] || options[:op] || :eq
        @member_type = options[:member_type] || :dimension
        @value = options[:value]
        @applied = false
      end

      def attribute_name
        @attribute_name ||= dimension? ? :key : :count
      end

      def dimension?
        member_type == :dimension
      end

      def measure?
        member_type == :measure
      end

      def applied!
        @applied = true
      end

      def applied?
        @applied
      end

       def delimited_value(for_eval=false)
        case value
        when nil then "nil"
        when String, Symbol then "'#{value}'"
        when Time  then for_eval ? "Time.parse('#{value}')" : "time(#{value})"
        else value.inspect
        end
      end

      def to_s(options={})
        properties = [member_type,name,attribute_name,operator,delimited_value]
        properties.pop if options[:exclude_value]
        properties.join("::")
      end

      def self.parse(filter_string,options={})
        new(nil).parse(filter_string,options)
      end

      def parse(filter_string,options={})
        parts = filter_string.split("::")
        @member_type = parts.shift.to_sym
        @name = parts.shift
        @attribute_name = parts.shift
        @operator = parts.shift.to_sym
        @value = parse_value(options[:value] || parts.shift || @value)
        self
      end

      def inspect
        ":#{member_type}s['#{name}'].#{attribute_name}.#{operator}(#{delimited_value(true)})"
      end

      def <=>(other)
        inspect <=> other.inspect
      end

      def ==(other)
        inspect == other.inspect
      end

      [:gt, :lt, :gte, :lte, :ne, :in, :nin, :eq].each do |operator|
        define_method(operator) do |*args|
          @value = args[0] if args.length > 0
          @operator = operator; self
        end unless method_defined?(operator)
      end

      def method_missing(sym,*args)
        super unless args.blank?
        @attribute_name = sym
        self
      end

      def matches(aggregation, tuple)
        #this check allows the database adapter to apply a filter at the db query level
        #Wonkavision will avoid the overhead of checking again if the store signals it has taken care of things
        return true if @applied || tuple.blank?

        assert_operator_matches_value

        matches_value extract_attribute_value_from_tuple(aggregation, tuple)
      end

      def matches_value(data)
        case operator
        when :gt then data ? data > value : false
        when :lt then data ? data < value : false
        when :gte then data ? data >= value : false
        when :lte then data ? data <= value : false
        when :in then value.include?(data)
        when :nin then !value.include?(data)
        when :ne then data != value
        when :eq then value == data
        else raise "Unknown filter operator #{operator}"
        end
      end

      def attribute_key(aggregation)
        attribute_key = attribute_name.to_s
        #If the attribute name is key, caption or sort, we need to find the real name of the underling
        # attribute
        if dimension?
          dimension = aggregation.dimensions[name]
          raise "Error applying a member filter: Dimension #{name} does not exist" unless dimension
          attribute_key = dimension.send(attribute_name).to_s if dimension.respond_to?(attribute_name)
        end
        attribute_key
      end

      private

      def parse_value(value_string)
        case value_string
        when /^\'.*\'$/ then value_string[1..-2]
        when /^time\(.*\)$/ then Time.parse(value_string[5..-2])
        when String then value_string.is_numeric? ? eval(value_string) : value_string
        else value_string
        end
      end

      # TODO: This is smelly - we should have a Tuple class that knows its aggregation
      # and can return this kind of information on demand - it is dirty business
      # that a filter class has to know the about the anatomy of a tuple to do its
      # job
      def extract_attribute_value_from_tuple(aggregation,tuple)
        val = tuple["#{member_type}s"] #dimensions or measures
        val = val[name.to_s] #measure name or dimension name

        if val
          val[attribute_key(aggregation)]
        end
      end

      def assert_operator_matches_value

        case operator
        when :gt, :lt, :gte, :lte then
          raise "A filter value is required for #{operator}" unless value
        when :in, :nin then
          raise "A filter value is required for #{operator}" unless value
          raise "The filter value for #{operator} must respond to :include?" unless value.respond_to?(:include?)
        end
      end

    end
  end
end
