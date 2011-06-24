require "test_helper"

class AttributeTest < ActiveSupport::TestCase
  context "Attribute" do
    setup do
      @attribute = Wonkavision::Analytics::Aggregation::Attribute.new(:my_attribute,:an_option=>true)
    end

    should "take its name from the constructor" do
      assert_equal :my_attribute, @attribute.name
    end

    should "take its options from the constructor" do
      assert_equal( { :an_option => true}, @attribute.options )
    end

    context "#extract" do
      should "extract a value from a hash based on the name of the attribute" do
        assert_equal "hi", @attribute.extract({ "my_attribute" => "hi"})
      end

    end


  end
end
