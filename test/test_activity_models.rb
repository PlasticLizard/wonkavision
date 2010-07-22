unless defined?(::TestEventHandler)
  class TestEventHandler
    include Wonkavision::EventHandler

    def self.knids
      @@knids ||= []
    end

    def self.callbacks
      @@callbacks ||= []
    end

    def self.reset
      @@knids = []
      @@callbacks = []
    end

    before_event :before
    def before
      TestEventHandler.callbacks << {:kind=>"before_event",:path=>event_context.path}
    end

    after_event do |handler|
      TestEventHandler.callbacks << {:kind=>"after_event", :path=>handler.event_context.path}
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

  class TestBusinessActivity
    include MongoMapper::Document

    acts_as_timeline

    event_namespace :test
    correlate_by    :test_id

    milestone :ms1, :evt1
    milestone :ms2, :evt2
    milestone :ms3, :evt3, '/not_test/evt4'

    map /not_test\/.*/i do
      import "evt4_test_map"
      string 'modified_another_field'=> "'#{context["another_field"]}' WAS SERVED!! OH YEAH!! IN-YOUR-FACE!!"
    end
  end

  Wonkavision::MessageMapper.register("evt4_test_map") do
    string 'test_id'
    date 'event_time'
  end

end