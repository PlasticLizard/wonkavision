require "test_helper"

class MemberFilterTest < ActiveSupport::TestCase
  context "MemberFilter" do
    setup do
      @dimension = Wonkavision::Analytics::MemberFilter.new(:a_dim,   :member_type=>:dimension)
      @measure = Wonkavision::Analytics::MemberFilter.new(:a_measure, :member_type=>:measure)
    end
    context "#attribute_name" do
      should "default to key for dimension" do
        assert_equal :key, @dimension.attribute_name
      end
      should "default to count for measure" do
        assert_equal :count, @measure.attribute_name
      end
    end
    context "#dimension?" do
      should "be true for dimension" do
        assert @dimension.dimension?
      end
      should "not be true for measure" do
        assert !@measure.dimension?
      end
    end
    context "#measure?" do
      should "be true for measure" do
        assert @measure.measure?
      end
      should "not be true for dimension" do
        assert !@dimension.measure?
      end
    end
    context "#operators" do
      should "set the operator property appropriately" do
        [:gt, :lt, :gte, :lte, :ne, :in, :nin].each do |op|
          assert_equal op, @dimension.send(op).operator
        end
      end

    end

    context "#matches" do
      setup do
        @tuple = {
          "measures" => { "a_measure" => { "sum" => 2.0, "count" => 5 } }
        }
        @aggregation = {}
        @dimension = {}
        @filter = Wonkavision::Analytics::MemberFilter.new(:a_measure, :member_type=>:measure,:value=>1)
      end
      should "return false for gt, lt, gte, lte if the data is nil" do
        @tuple["measures"]["a_measure"]["count"] = nil
        [:gt, :lt, :gte, :lte].each do |op|
          @filter.send(op)
          assert_equal false, @filter.matches(@aggregation, @tuple)
        end
      end
      should "evaluate gt, gte" do
        [:gt, :gte].each do |op|
          @filter.send(op,4)
          assert @filter.matches(@aggregation, @tuple)
        end
      end
      should "evaluate lt, lte" do
        [:lt, :lte].each do |op|
          @filter.send(op,6)
          assert @filter.matches(@aggregation, @tuple)
        end
      end
      should "evaluate in" do
        @filter.in([4,5,6])
        assert @filter.matches(@aggregation, @tuple)
      end
      should "evalute nin" do
        @filter.nin([6,7,8])
        assert @filter.matches(@aggregation, @tuple)
      end
      should "evaluate eq" do
        @filter.eq(5)
        assert @filter.matches(@aggregation, @tuple)
      end
      should "evaluate ne" do
        @filter.ne(6)
        assert @filter.matches(@aggregation, @tuple)
      end
    end

    context "#extract_attribute_value_from_tuple" do
      setup do
        @tuple = {
          "dimensions" => { "a_dimension" => { "akey" => "abc" } },
          "measures" => { "a_measure" => { "sum" => 2.0, "count" => 5 } }
        }
        @aggregation = {}
        @dimension = {}
      end
      context "for a dimension filter" do
        setup do
          @filter = Wonkavision::Analytics::MemberFilter.new(:a_dimension)
          @aggregation.expects(:dimensions).returns( { :a_dimension => @dimension } )
        end
        should "extract a dimension value from a tuple message" do
          @dimension.expects(:key).returns(:akey)
          assert_equal "abc", @filter.send(:extract_attribute_value_from_tuple,@aggregation,@tuple)
        end
        should "extract a dimension value with a custom attribute" do
          @filter.instance_variable_set("@attribute_name","akey")
          assert_equal "abc", @filter.send(:extract_attribute_value_from_tuple,@aggregation,@tuple)
        end
      end
      context "for a measure filter" do
        setup do
          @filter = Wonkavision::Analytics::MemberFilter.new(:a_measure, :member_type=>:measure)
        end
        should "extract a measure value" do
          assert_equal 5, @filter.send(:extract_attribute_value_from_tuple,@aggregation,@tuple)
        end
      end
    end

    context "#assert_operator_matches_value" do
      should "raise an exception if inappropriately nil" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi)
        [:gt, :lt, :gte, :lte, :in, :nin].each do |op|
          filter.send(op)
          assert_raise(RuntimeError) {  filter.send :assert_operator_matches_value }
        end
      end
      should "raise an exception if 'in' and 'nin' are not given an array" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi, :value=>:ho)
        [:in,:nin].each do |op|
          filter.send(op)
          assert_raise(RuntimeError) { filter.send :assert_operator_matches_value }
        end
      end
      should "not raise an exception otherwise" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi, :operator=>:gt, :value=>1)
        filter.send(:assert_operator_matches_value)
      end
    end

  end
end
