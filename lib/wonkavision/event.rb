module Wonkavision

  class Event < Wonkavision::EventPathSegment

    def initialize(name, namespace, opts={})
      super name,namespace,opts
      @source_events = []
      source_events(*opts.delete(:source_events)) if opts.keys.include?(:source_events)
    end

    def matches(event_path)
      event_path == path || @source_events.detect{|evt|evt.matches(event_path)} != nil
    end

    def notify_subscribers(event_data,event_path)
      super(event_data,self.path)
    end

    def source_events(*args)
      return @source_events if args.blank?
      @source_events = @source_events.concat(args.map do |source|
         source_ns = namespace
         if (source=~/^\/.*/)
           source_ns = root_namespace
           source = source[1..-1]
         end
         source_ns.find_or_create(source)
      end)
    end
  end

end
  