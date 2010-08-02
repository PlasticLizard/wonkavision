module Wonkavision
  module Plugins
    module BusinessActivity
      class EventBinding < Wonkavision::EventBinding
        attr_reader :correlation
        def initialize(*args)
          super(*args)
          if (correlation_args = @options.delete(:correlate_by))
            correlation_args = [correlation_args] unless correlation_args.is_a?(Array)
            @correlation = BusinessActivity.normalize_correlation_ids(*correlation_args)
          end
        end
      end
    end
  end
end