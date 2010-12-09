module Wonkavision
  module MessageMapper
    module IndifferentAccess
      def [](key)
        key = key.to_s
        super(key)
      end

      def []=(key,val)
        super(key.to_s,val)
      end

      def include?(key)
        super(key.to_s)
      end

      def delete(key)
        super(key.to_s)
      end

      def method_missing(sym,*args,&block)
        return self[sym.to_s[0..-2]] = args[0] if sym.to_s =~ /.*=$/
        return self[sym] if self.keys.include?(sym.to_s)
        nil
      end
    end
  end

end

