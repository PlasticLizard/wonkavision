require "test_helper"

class CellSetTest < ActiveSupport::TestCase
  Query = Wonkavision::Analytics::Query

  context "CellSet" do
    context "#initialize" do
      should "popupate from the passed in tuples array" do
        assert_equal [1,2,3], Wonkavision::Analytics::CellSet.new(nil,nil,[1,2,3])
      end

    end


  end
end
