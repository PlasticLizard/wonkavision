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

    context "#select aliases" do
      should "proxy to select with an appropriate axis specified" do
        @query.columns :hi, :there
        assert_equal [:hi, :there], @query.axes[0]
      end

    end

    context "#selected_dimensions" do
      should "collect dimensions from each axis" do
        @query.select :c, :d; @query.select :b, :a, :on => :rows
        assert_equal [:c,:d,:b,:a], @query.selected_dimensions
      end
    end

    context "#referenced_dimensions" do
      should "match selected dimensions with no dimension filters" do
        @query.select :c, :d
        assert_equal @query.selected_dimensions.map{|d|d.to_s}, @query.referenced_dimensions
      end
      should "include filter dimensions in the presence of a dimension filter"do
        @query.select(:c,:d).where(:e=>:f)
        assert_equal 3,  @query.referenced_dimensions.length
        assert_equal [], @query.referenced_dimensions - ['c', 'd', 'e']
      end
    end

    context "#selected_measures" do
      should "collect selected measures" do
        @query.measures :a, :b, :c
        assert_equal [:a, :b, :c], @query.selected_measures
      end
      should "default to count" do
        assert_equal [:count], @query.selected_measures
      end
    end

    context "#matches_filter?" do
      should "return true if all filters are applied" do
        @query.expects(:all_filters_applied?).returns(true)
        assert @query.matches_filter?(nil,nil)
      end
    end

    context "#where" do
      should "convert a symbol to a MemberFilter" do
        @query.where :a=>:b
        assert @query.filters[0].kind_of?(Wonkavision::Analytics::MemberFilter)
      end

      should "append filters to the filters array" do
        @query.where :a=>:b, :c=>:d
        assert_equal 2, @query.filters.length
      end

      should "set the member filters value from the hash" do
        @query.where :a=>:b
        assert_equal :b, @query.filters[0].value
      end

      should "add dimension names to the slicer" do
        @query.where :dimensions.a => :b
        assert @query.slicer_dimensions.include?(:a)
      end

      should "not add measure names to the slicer" do
        @query.where :measures.a => :b
        assert @query.slicer_dimensions.include?(:a) == false
      end

    end

    context "#slicer" do
      setup do
        @query.select :a, :b
        @query.where :dimensions.b=>:b, :dimensions.c=>:c
      end
      should "include only dimensions not on another axis" do
        assert_equal [:c], @query.slicer_dimensions
      end

    end

  end
end
