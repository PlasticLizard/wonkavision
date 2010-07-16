require "test_helper"

class Wonkavision::MessageMapperTest < ActiveSupport::TestCase
  context "Wonkavision::MessageMapper.execute" do
    setup do
      Wonkavision::MessageMapper.register("test_map") do
        context["i_was_here"] = true
      end
    end
    should "evaluate the named block against a new map" do
      data = {}
      Wonkavision::MessageMapper.execute("test_map",data)
      assert data["i_was_here"]
    end
    should "raise an error if the map is missing" do
      assert_raise RuntimeError do
        Wonkavision::MessageMapper.execute("I'm not really here", {})
      end
    end
  end
end