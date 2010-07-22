# The note you see below, 'Almost all of this callback stuff...', along with all the code adapted from ActiveSupport,
# is in turn adapted from MongoMapper, and for the same reasons.
# encoding: UTF-8
# Almost all of this callback stuff is pulled directly from ActiveSupport
# in the interest of support rails 2 and 3 at the same time and is the
# same copyright as rails.
module Wonkavision
  module Plugins
    module Callbacks
      def self.configure(handler,options)
        handler.define_wonkavision_callbacks :before_event,
                                 :after_event
        
        handler.alias_method_chain :handle_event, :callbacks
      end

      module ClassMethods
        #The ODM library may already have taken care of mixing in callback functioanlity,
        #in which case we'll just use that
        def define_wonkavision_callbacks(*callbacks)
          callbacks.each do |callback|
            class_eval <<-"end_eval"
              def self.#{callback}(*methods, &block)
                callbacks = CallbackChain.build(:#{callback}, *methods, &block)
                @#{callback}_callbacks ||= CallbackChain.new
                @#{callback}_callbacks.concat callbacks
              end

              def self.#{callback}_callback_chain
                @#{callback}_callbacks ||= CallbackChain.new

                if superclass.respond_to?(:#{callback}_callback_chain)
                  CallbackChain.new(
                    superclass.#{callback}_callback_chain +
                    @#{callback}_callbacks
                  )
                else
                  @#{callback}_callbacks
                end
              end
            end_eval
          end
        end
      end

      module InstanceMethods
        def handle_event_with_callbacks
          ctx = @wonkavision_event_context
          run_wonkavision_callbacks(:before_event)
          handle_event_without_callbacks
          run_wonkavision_callbacks(:after_event)
        end
        
        def run_wonkavision_callbacks(kind, options={}, &block)
          callback_chain_method = "#{kind}_callback_chain"
          return unless self.class.respond_to?(callback_chain_method)
          self.class.send(callback_chain_method).run(self, options, &block)          
        end
      end

      class CallbackChain < Array
        def self.build(kind, *methods, &block)
          methods, options = extract_options(*methods, &block)
          methods.map! { |method| Callback.new(kind, method, options) }
          new(methods)
        end

        def run(object, options={}, &terminator)
          enumerator = options[:enumerator] || :each

          unless block_given?
            send(enumerator) { |callback| callback.call(object) }
          else
            send(enumerator) do |callback|
              result = callback.call(object)
              break result if terminator.call(result, object)
            end
          end
        end

        def replace_or_append!(chain)
          if index = index(chain)
            self[index] = chain
          else
            self << chain
          end
          self
        end

        def find(callback, &block)
          select { |c| c == callback && (!block_given? || yield(c)) }.first
        end

        def delete(callback)
          super(callback.is_a?(Callback) ? callback : find(callback))
        end

        private
        def self.extract_options(*methods, &block)
          methods.flatten!
          options = methods.extract_options!
          methods << block if block_given?
          return methods, options
        end

        def extract_options(*methods, &block)
          self.class.extract_options(*methods, &block)
        end
      end

      class Callback
        attr_reader :kind, :method, :identifier, :options

        def initialize(kind, method, options={})
          @kind       = kind
          @method     = method
          @identifier = options[:identifier]
          @options    = options
        end

        def ==(other)
          case other
            when Callback
              (self.identifier && self.identifier == other.identifier) || self.method == other.method
            else
              (self.identifier && self.identifier == other) || self.method == other
          end
        end

        def eql?(other)
          self == other
        end

        def dup
          self.class.new(@kind, @method, @options.dup)
        end

        def hash
          if @identifier
            @identifier.hash
          else
            @method.hash
          end
        end

        def call(*args, &block)
          evaluate_method(method, *args, &block) if should_run_callback?(*args)
        rescue LocalJumpError
          raise ArgumentError,
                "Cannot yield from a Proc type filter. The Proc must take two " +
                        "arguments and execute #call on the second argument."
        end

        private
        def evaluate_method(method, *args, &block)
          case method
            when Symbol
              object = args.shift
              object.send(method, *args, &block)
            when String
              eval(method, args.first.instance_eval { binding })
            when Proc, Method
              method.call(*args, &block)
            else
              if method.respond_to?(kind)
                method.send(kind, *args, &block)
              else
                raise ArgumentError,
                      "Callbacks must be a symbol denoting the method to call, a string to be evaluated, " +
                              "a block to be invoked, or an object responding to the callback method."
              end
          end
        end

        def should_run_callback?(*args)
          [options[:if]].flatten.compact.all? { |a| evaluate_method(a, *args) } &&
                  ![options[:unless]].flatten.compact.any? { |a| evaluate_method(a, *args) }
        end
      end
    end
  end
end
