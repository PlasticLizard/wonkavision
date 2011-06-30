require "test_helper"

class ApiUtilsTest < ActiveSupport::TestCase
  context Wonkavision::Analytics::ApiUtils do
  
      context "#query_from_params" do
        setup do
          @params = {
            "columns" => ["a","b"],
            "rows" => ["c","d"], 
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
              assert_equal @query.axes[idx], @params[axis]
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

  end
end
