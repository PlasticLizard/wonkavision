require "test_helper"
require "cgi"

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

    context "#inspect" do
      should "should be 'eval'able to reproduce the filter" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).eq(3)
        filter2 = eval(filter.inspect)
        assert_equal filter, filter2
      end
      should "represent nil value with an unquoted string 'nil'" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi)
        assert_equal ":dimensions['hi'].key.eq(nil)", filter.inspect
      end
      should "wrap strings in a single quote" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).ne("whatever")
        assert_equal ":dimensions['hi'].key.ne('whatever')", filter.inspect
      end
      should "prefix member filters with :members" do
        filter = :measures.a_measure.gt(3)
        assert_equal ":measures['a_measure'].count.gt(3)", filter.inspect
      end
      should "produce 'eval'able measure filter" do
        filter = :measures.a_measure.average.lt(5)
        filter2 = eval(filter.inspect)
        assert_equal filter, filter2
      end
    end

     context "#to_s" do
      should "produce a canonical string representation of a member filter" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).eq(3)
        assert_equal "dimension::hi::key::eq::3", filter.to_s
      end
      should "should be 'parse'able to reproduce the filter" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).eq(3)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s)
        assert_equal filter, filter2
      end
      should "wrap strings in a single quote" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).ne("whatever")
        assert_equal "dimension::hi::key::ne::'whatever'", filter.to_s
      end
      should "be able to represent a parseable time as a filter value" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(Time.now)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s)
        assert_equal filter, filter2
      end
      should "omit the value portion of the string when requested" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(5)
        assert_equal "dimension::hi::key::gt", filter.to_s(:exclude_value=>true)
      end
      should "be able to parse a value-less emission" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(5)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s(:exclude_value=>true))
        assert_nil filter2.value
        filter2.value = 5
        assert_equal filter, filter2
      end
      should "take its value from an option on parse" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(5)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s(:exclude_value=>true),
                                                             :value=>5)
        assert_equal filter, filter2
      end
    end

  end
end
