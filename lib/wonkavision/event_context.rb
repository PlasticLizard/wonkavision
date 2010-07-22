module Wonkavision
  class EventContext
    attr_accessor :data, :path, :binding, :callback

    def initialize(data,path,binding,callback)
      @data, @path, @binding, @callback = data, path, binding, callback
    end
  end
end
