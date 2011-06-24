module Wonkavision
  module Analytics
    class CellSet
      class Member
        attr_reader :dimension, :attributes
        def initialize(dimension,member_data)
          @dimension = dimension
          @attributes = member_data
        end

        def caption
          attributes[dimension.definition.caption.to_s]
        end

        def key
          attributes[dimension.definition.key.to_s]
        end

        def sort
          attributes[dimension.definition.sort.to_s]
        end

        def <=>(other)
          sort <=> other.sort
        end

        def to_s
          key.to_s
        end

        def to_key
          key
        end

      end

    end
  end
end
