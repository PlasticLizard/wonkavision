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

      def self.make_indifferent(hash)
        class << hash;include IndifferentAccess; end
      end

      def merge!(other)
        other.stringify_keys!
        super(other)
      end

      def merge(other)
        out = IndifferentHash.new
        out.merge!(self)
        out.merge!(other)
        out
      end
    end

    class IndifferentHash < Hash
      include IndifferentAccess
    end
    
  end
end



