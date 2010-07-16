module Wonkavision
  class EventCoordinator

    attr_reader :root_namespace

    def initialize
      @root_namespace = Wonkavision::EventNamespace.new
      @lock = Mutex.new
      #@event_cache = {}
      @incoming_event_filters = []
    end

    def before_receive_event(&block)
      @incoming_event_filters << block
    end

    def clear_filters
      @incoming_event_filters = []
    end

    def configure(&block)
      self.instance_eval(&block)
    end

    def map ()
      yield root_namespace if block_given?
    end

    def subscribe(event_path,final_segment_type=nil,&block)
      event_path, final_segment_type = *detect_final_segment(event_path) unless final_segment_type
      segment = (event_path.blank? ? root_namespace : root_namespace.find_or_create(event_path,final_segment_type))
      segment.subscribe(&block)
    end

    def receive_event(event_path, event_data)
      @lock.synchronize do
                          #If process_incoming_event returns nil or false, it means a filter chose to abort
                          #the event processing, in which case we'll break for lunch.
        return unless event_data = process_incoming_event(event_path,event_data)

        event_path = Wonkavision.normalize_event_path(event_path)
        targets = root_namespace.find_matching_events(event_path)
        #If the event wasn't matched, maybe someone is subscribing to '/*' ? 
        targets = [root_namespace] if targets.blank?
        targets.each{|target|target.notify_subscribers(event_data,event_path)}
      end
    end

    protected
    def process_incoming_event(event_path,event_data)
      return nil unless event_data
      @incoming_event_filters.each do |filter_block|
        if (filter_block.arity < 1)
          event_data = event_data.instance_eval(&filter_block)
        elsif filter_block.arity == 1
          event_data = filter_block.call(event_data)
        else
          event_data = filter_block.call(event_data,event_path)
        end
        return nil unless event_data
      end
      event_data
    end

    def detect_final_segment(event_path)
      parts = Wonkavision.split(event_path)
      if parts[-1] == Wonkavision.namespace_wildcard_character
        [Wonkavision.join(parts.slice(0..-2)),:namespace]
      else
        [event_path,:event]
      end
    end

  end
end
