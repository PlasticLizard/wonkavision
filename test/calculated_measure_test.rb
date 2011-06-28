require "test_helper"

class CalculatedMeasureTest < ActiveSupport::TestCase

  context "CalculatedMeasure" do
    setup do
      @calc = Wonkavision::Analytics::CellSet::CalculatedMeasure.new( :my_calc,
                                                                      Time.now,
                                                                      :format=>:dollars,
                                                                      :calculation=>
                                                                      Proc.new{ day * month })

    end
    should "calculate a value based on the cell" do
      assert_equal Time.now.day * Time.now.month, @calc.value
    end

    should "present an appropriately formatted value" do
      assert_equal "$#{Time.now.day*Time.now.month}.00", @calc.formatted_value
    end

  end
end
