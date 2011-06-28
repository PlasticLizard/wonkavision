require "test_helper"

class SymbolTest < ActiveSupport::TestCase
  context "Symbol extensions" do
    setup do
      @symbol = :member
    end
    context "#key, #caption and #sort" do
      should "produce MemberFilters of type dimension" do
        [:key,:caption,:sort].each do |method|
          filter = @symbol.send(method)
          assert_equal @symbol, filter.name
          assert_equal :dimension, filter.member_type
          assert_equal method, filter.attribute_name
        end
      end
    end
    context "#sum, #sum2, #count" do
      should "produce MemberFilters of type measure" do
        [:sum,:sum2,:count].each do |method|
          filter = @symbol.send(method)
          assert_equal @symbol, filter.name
          assert_equal :measure, filter.member_type
          assert_equal method, filter.attribute_name
        end
      end
    end

    # context "#[]" do
    #   should "produce a MemberFilter with the attribute name specified by the indexer" do
    #     filter = @symbol[:an_attribute]
    #     assert_equal @symbol, filter.name
    #     assert_equal :an_attribute, filter.attribute_name
    #   end
    # end
   
    context "when the symbol is ':dimensions'" do
      should "produce a MemberFilter with a dimension name as specified and a default attribute name" do
        filter = :dimensions.a_dimension
        assert_equal :a_dimension, filter.name
        assert_equal :key, filter.attribute_name
        assert_equal :dimension, filter.member_type
      end
    end
    context "when the symbol is ':measures'" do
      should "produce a MemberFilter with a measure name as specified and a default attribute name" do
        filter = :measures.a_measure
        assert_equal :a_measure, filter.name
        assert_equal :count, filter.attribute_name
        assert_equal :measure, filter.member_type
      end
    end

  end

end
