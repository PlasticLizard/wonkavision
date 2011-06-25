module Wonkavision
	module Analytics
		class Transformation
			attr_accessor :name, :transformer

			def initialize(name, &block)
				@name = name
				@transformer = block
			end	
			
			def apply(message)
				@transformer ? @transformer.call(message) : message
			end
		end
	end
end