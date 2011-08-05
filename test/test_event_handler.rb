unless defined?(::TestEventHandler)
  class TestEventHandler
    include Wonkavision::EventHandler

    def self.knids
      @@knids ||= []
    end

    # def self.callbacks
    #   @@callbacks ||= []
    # end

    def self.reset
      @@knids = []
      #@@callbacks = []
    end

    event_namespace :vermicious

    handle :knid do |data,path|
      TestEventHandler.knids << [data,path]
    end

    #handle events in the vermicious namespace
    handle "*" do |data,path|
      TestEventHandler.knids << [data,path] if path !~ /.*knid/
    end

    #handle ALL events in any namespace
    handle "/*" do |data,path|
      TestEventHandler.knids << [data,path] if path !~ /^vermicious.*/
    end

  end

  Wonkavision::MessageMapper.register("evt4_test_map") do
    string 'test_id'
    time 'event_time'
  end

end
