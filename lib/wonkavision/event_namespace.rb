module Wonkavision

  class EventNamespace < EventPathSegment

    attr_reader :children

    def initialize(name=nil,namespace = nil,opts={})
      super name, namespace,opts
      @children=HashWithIndifferentAccess.new
    end

    def find_or_create (path, final_segment_type = :event)
      if path.is_a?(Array)
        child_name = path.shift
        segment_type = path.blank? ? final_segment_type : :namespace
        child = @children[child_name] ||=  self.send(segment_type,child_name)
        return child if path.blank?
        raise "Events cannot have children. The path  you requested is not valid" if child.is_a?(Wonkavision::Event)
        child.find_or_create(path,final_segment_type)
      else
        path = Wonkavision.normalize_event_path(path)
        source_ns = self
        if (Wonkavision.is_absolute_path(path)) #indicates an absolute path, because it begins with a '/'
          source_ns = root_namespace
          path = path[1..-1]
        end
        source_ns.find_or_create(path.split(Wonkavision.event_path_separator), final_segment_type)
      end
    end

    def find_matching_events (event_path)
      events = []
      @children.each_value do |child|
        if (child.is_a?(Wonkavision::Event))
          events << child if child.matches(event_path)
        elsif (child.is_a?(Wonkavision::EventNamespace))
          events.concat(child.find_matching_events(event_path))
        else
          raise "An unexpected child type was encountered in find_matching_events #{child.class}"
        end
      end
      events
    end

    #dsl
    def namespace(*args)
      return super if args.blank?
      name, opts = args.shift, (args.shift || {})
      ns = Wonkavision::EventNamespace.new(name,self,opts)
      yield ns if block_given?
      @children[ns.name] = ns
      ns
    end

    def event(*args)
      name, opts  = args.shift, args.extract_options!
      opts[:source_events] = (opts[:source_events] || []).concat(args) unless args.blank?
      evt = Wonkavision::Event.new(name,self,opts)
      yield evt if block_given?
      @children[evt.name] = evt
      evt
    end
  end
end
