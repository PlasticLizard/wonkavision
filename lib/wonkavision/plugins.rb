#This concept (and code) shamelessly stolen from MongoMapper
#(http://railstips.org/blog/archives/2010/02/21/mongomapper-07-plugins/)
#as so much of my Ruby code tends to be.  I added a few little things and changed some
#names to avoid conflicts.
module Wonkavision
  module Plugins
    def wonkavision_plugins
      @wonkavision_plugins ||= []
    end

    def has_wonkavision_plugin?(plugin)
      wonkavision_plugins.detect{|p|p==plugin}
    end

    def ensure_wonkavision_plugin(plugin,option={})
      use(plugin,options) unless has_wonkavision_plugin?(plugin)
    end

    def plug(mod,options={})
      extend mod::ClassMethods     if mod.const_defined?(:ClassMethods)
      include mod::InstanceMethods if mod.const_defined?(:InstanceMethods)
      extend mod::Fields           if mod.const_defined?(:Fields)
      include mod::Fields          if mod.const_defined?(:Fields)
      mod.configure(self,options)  if mod.respond_to?(:configure)
      wonkavision_plugins << mod
    end
    alias use plug
    
  end
end
