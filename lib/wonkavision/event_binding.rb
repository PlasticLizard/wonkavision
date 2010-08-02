module Wonkavision

  class EventBinding
    attr_reader :name, :events, :options

    def initialize(name,handler,*args)
      args.flatten!
      @options = args.extract_options!
      @handler = handler
      @name = name
      @events = []
      args = [@name] if args.blank? || args.flatten.blank?
      @events = args.flatten.map{|evt_name|@handler.event_path(evt_name)}
    end

    def subscribe_to_events(&block)
      @events.each do |event|
        Wonkavision.event_coordinator.subscribe(event,&block)
      end
    end
  end
end