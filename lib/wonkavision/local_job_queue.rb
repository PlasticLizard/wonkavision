require 'thread'

module Wonkavision
  class LocalJobQueue
    attr_reader :queue
    def initialize(options={})
      worker_count = options[:workers] || 2
      @queue = Queue.new
      @workers = []
      worker_count.times do
        Thread.new do
          while true
            if msg = @queue.pop
              Wonkavision.event_coordinator.receive_event(msg[0],msg[1])
            else
              sleep 0.1
            end
          end
        end
      end
    end

    def publish(event_path,event)
      @queue << [event_path, event]
    end

  end
end
