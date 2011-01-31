require "test_helper"

class QueryTest < ActiveSupport::TestCase
  Query = Wonkavision::Analytics::Query

  context "Query" do
    setup do
      @query = Query.new
    end

    context "Class methods" do
      context "#axis_ordinal" do
        should "convert nil or empty string to axis zero" do
          assert_equal 0, Query.axis_ordinal(nil)
          assert_equal 0, Query.axis_ordinal("")
        end
        should "convert string integers into real integers" do
          assert_equal 3, Query.axis_ordinal("3")
        end
        should "correctly interpret named axes" do
          ["Columns", :rows, :PAGES, "chapters", "SECTIONS"].each_with_index do |item,idx|
            assert_equal idx, Query.axis_ordinal(item)
          end
        end

      end
    end

    context "#select" do
      should "associate dimensions with the default axis (columns)" do
        @query.select :hi, :there
        assert_equal [:hi,:there], @query.axes[0]
      end
      should "associate dimensions with the specified axis" do
        @query.select :hi, :there, :on => :rows
        assert_equal [:hi, :there], @query.axes[1]
      end
    end

    context "#selected_dimensions" do
      should "collection dimensions from each axis" do
        @query.select :c, :d; @query.select :b, :a, :on => :rows
        assert_equal [:c,:d,:b,:a], @query.selected_dimensions
      end
    end


  end
end
