require "test_helper"

class TransformationTest < ActiveSupport::TestCase
  context "Transformation" do
    setup do
      @transform = 
      Wonkavision::Analytics::Transformation.new("hi") do |message|
        message[:items].map do |item|
          {:name=>item[:name], :age=>item[:age] * 2}   
        end
      end
    end

    should "take its name from the constructor" do
      assert_equal "hi", @transform.name
    end

    should "set the transformer from the provided block" do
      assert_not_nil @transform.transformer
    end   

    context "#apply" do
      setup do
        @result = @transform.apply( {
          :items => [{:name=>"billy",:age=>97,:fear=>"spiders"},
                     {:name=>"artimus",:age=>1,:fear=>"poverty"}]
        })
      end
      should "apply the transformation to the message" do
        assert_equal @result,
                    [{:name=>"billy",:age=>97 * 2},
                     {:name=>"artimus",:age=>1 * 2}]
      end
    end

  end
end
