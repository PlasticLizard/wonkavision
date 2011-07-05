require "test_helper"

class ApiUtilsTest < ActiveSupport::TestCase
  context Wonkavision::Analytics::ApiUtils do
  
      context "#query_from_params" do
        setup do
          @params = {
            "columns" => "a,b",
            "rows" => "c, d ", 
            "pages" => ["e","f"],
            "chapters" => ["g","h"],
            "sections" => ["i","j"],
            "measures" => ["k","l"],
            "filters" => [:dimensions.a.caption.eq(2).to_s, :measures.k.ne("b").to_s]
          }
          @query = Wonkavision::Analytics::ApiUtils.query_from_params(@params)

        end
        
        should "extracted dimensions into each named axis" do
          (0..4).each do |axis_ordinal|
            ["columns","rows","pages","chapters","sections"].each_with_index do |axis,idx|
              assert_equal @query.axes[idx], Wonkavision::Analytics::ApiUtils.parse_list(@params[axis])
            end
          end
        end

        should "extract measures" do
          assert_equal @query.measures, @params["measures"]
        end

        should "extract each filter" do
          assert_equal 2, @query.filters.length
        end

        should "convert strings to MemberFitler" do
          @query.filters.each do |f|
            assert f.kind_of?(Wonkavision::Analytics::MemberFilter)
          end
        end

        should "properly parse each filter" do
          assert_equal @query.filters[0].member_type, :dimension
          assert_equal @query.filters[0].operator, :eq
          assert_equal @query.filters[0].value, 2
          assert_equal @query.filters[0].attribute_name, 'caption'

          assert_equal @query.filters[1].member_type, :measure
          assert_equal @query.filters[1].operator, :ne
          assert_equal @query.filters[1].value, "b"
          assert_equal @query.filters[1].attribute_name, 'count'
        end
    end

    context "parse_list" do
      should "return nil if the input is blank" do
        assert_equal nil, Wonkavision::Analytics::ApiUtils.parse_list("")
      end
      should "return an array if the input is an array" do
        assert_equal [1,2,3], Wonkavision::Analytics::ApiUtils.parse_list([1,2,3])
      end
      should "return a single element array if the input is a single string" do
        assert_equal ["a"], Wonkavision::Analytics::ApiUtils.parse_list("a")
      end
      should "split a string by commas if the input is a comma string" do
        assert_equal ["a","b","c"], Wonkavision::Analytics::ApiUtils.parse_list("a, b,   c   ")
      end
    end

  end
end
