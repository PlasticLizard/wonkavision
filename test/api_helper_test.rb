require "test_helper"
require "wonkavision/api/helper"

class ApiHelperTest < ActiveSupport::TestCase
  setup do
    @helper = Wonkavision::Api::Helper.new("Ns")
  end

  context "#constantize" do
    should "prepend the namespace and constantize" do
      assert_equal Ns::Aggregation, @helper.constantize("Aggregation")
    end
  end

  context "#query_from_params" do
    setup do
      @params = {
        "columns" => "a|b",
        "rows" => "c|d ", 
        "pages" => ["e","f"],
        "chapters" => ["g","h"],
        "sections" => ["i","j"],
        "measures" => ["k","l"],
        "filters" => [:dimensions.a.caption.eq(2).to_s, :measures.k.ne("b").to_s].join("|")
      }
      @query = @helper.query_from_params(@params)

    end
    
    should "extract dimensions into each named axis" do
      (0..4).each do |axis_ordinal|
        ["columns","rows","pages","chapters","sections"].each_with_index do |axis,idx|
          assert_equal @helper.parse_list(@params[axis]), @query.axes[idx]
        end
      end
    end

    should "extract measures" do
      assert_equal @params["measures"], @query.measures
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
      assert_equal :dimension, @query.filters[0].member_type
      assert_equal :eq, @query.filters[0].operator
      assert_equal 2, @query.filters[0].value
      assert_equal 'caption', @query.filters[0].attribute_name

      assert_equal :measure, @query.filters[1].member_type
      assert_equal :ne, @query.filters[1].operator
      assert_equal "b", @query.filters[1].value
      assert_equal 'count', @query.filters[1].attribute_name
    end
  end

  context "facts_for" do
    setup do
      result = {:some=>:data}
      class << result; include Wonkavision::Analytics::Paginated; end

      @helper.expects(:facts_query_from_params).
        with(:aggregation=>"Aggregation").
        returns([:hi,{:ho=>:sailor}])
       Ns::Aggregation.expects(:facts_for).with(:hi,{:ho=>:sailor}).returns(result)
       @response = @helper.facts_for({:aggregation=>"Aggregation"})
    end
    should "set the facts class" do
      assert_equal "TestFacts", @response[:facts_class]
    end
    should "return the data" do
      assert_equal( {:some=>:data}, @response[:data] )
    end
    should "include pagination data" do
      assert @response[:pagination]
    end
  end

  context "facts_query_from_params" do
    setup do
      @params = {
        "filters" => [:dimensions.a.caption.eq(2).to_s, :measures.k.ne("b").to_s].join("|"),
        "page" => "2",
        "per_page" => "50",
        "sort" => "a:1|b:-1"
      }
      @filters, @options = @helper.facts_query_from_params(@params)
    end
    should "extract each filter" do
      assert_equal 2, @filters.length
    end

    should "convert strings to MemberFitler" do
      @filters.each do |f|
        assert f.kind_of?(Wonkavision::Analytics::MemberFilter)
      end
    end

    should "extract the options" do
      assert_equal 2, @options[:page]
      assert_equal 50, @options[:per_page]
      assert_equal [["a",1],["b",-1]], @options[:sort]
    end
  end

  context "parse_list" do
    should "should return nil if the input is blank" do
      assert_equal nil, @helper.parse_list("")
    end
    should "return an array if the input is an array" do
      assert_equal [1,2,3], @helper.parse_list([1,2,3])
    end
    should "return a single element array if the input is a single string" do
      assert_equal ["a"], @helper.parse_list("a")
    end
    should "split a string by commas if the input is a comma string" do
      assert_equal ["a","b","c"], @helper.parse_list("a| b |   c   ")
    end
  end

  context "parse_sort_list" do
    should "parse a string representing a list of sort criteria into a two dimensional array" do
      assert_equal [["a",1],["b",-1]], @helper.parse_sort_list("a:1|b:-1")
    end
  end

end
