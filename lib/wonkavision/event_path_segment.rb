module Wonkavision
  class EventPathSegment
    attr_reader :name, :namespace, :options, :subscribers

    def initialize(name = nil, namespace = nil, opts={})
      @name = name
      @namespace = namespace
      @options = opts
      @subscribers = []
    end

    def path
      Wonkavision.join(namespace.blank? ? nil : namespace.path,name)
    end
    
    def subscribe(&block)
      @subscribers << block
      self
    end   

    def notify_subscribers(event_data, event_path=self.path)
      @subscribers.each do |sub|
        sub.call(event_data,event_path)
      end
      namespace.notify_subscribers(event_data,event_path) if namespace
    end

    def root_namespace
      cur_namespace = self
      while (cur_namespace.namespace)
        cur_namespace=cur_namespace.namespace
      end
      cur_namespace
    end

  end
end