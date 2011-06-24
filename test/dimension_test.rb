require "test_helper"

class DimensionTest < ActiveSupport::TestCase

  Dimension = Wonkavision::Analytics::Aggregation::Dimension

  context "Dimension" do
    context "Basic Initialization" do
      setup do
        @dimension = Dimension.new :hi, :option=>true
      end

      should "take its name from the constructor" do
        assert_equal :hi, @dimension.name
      end

      should "take its options from the constructor" do
        assert_equal( { :option => true}, @dimension.options )
      end

      should "default the key sort and caption properties to name" do
        assert_equal :hi, @dimension.key
        assert_equal :hi, @dimension.sort
        assert_equal :hi, @dimension.caption
      end

      should "create an attribute for the key" do
        assert_equal 1, @dimension.attributes.length
        assert @dimension.attributes[:hi]
      end

    end
    context "When initialized via options" do
      setup do
        @dimension = Dimension.new :hi, :key=>:k, :sort => :s, :caption => :c
      end

      should "set the special attribute properties from the options" do
        assert_equal :k, @dimension.key
        assert_equal :s, @dimension.sort
        assert_equal :c, @dimension.caption
      end

      should "create attributes for each attribute property" do
        assert_equal 3, @dimension.attributes.length
        assert @dimension.attributes[:k]
        assert @dimension.attributes[:s]
        assert @dimension.attributes[:c]
      end
    end

    context "when initialized via block" do
      setup do
        @dimension = Dimension.new :hi do
          key :k, :key_option=>true
          sort_by :s, :sort_option=>true
          caption :c, :caption_option=>true
          attribute :a, :attribute_option=>true
        end
      end
      should "set the special attribute properties from theblock" do
        assert_equal :k, @dimension.key
        assert_equal :s, @dimension.sort
        assert_equal :c, @dimension.caption
      end
      should "create attributes for each attribute and attribute property" do
        assert_equal 4, @dimension.attributes.length
        assert @dimension.attributes[:k]
        assert @dimension.attributes[:s]
        assert @dimension.attributes[:c]
        assert @dimension.attributes[:a]
      end
    end

    context "DSL methods" do
      setup do
        @dimension = Dimension.new :hi
      end
      context "#attribute" do
        setup do
          @dimension.attribute :a, :b, :c=>:d, :e=>:f
        end
        should "create an attribute for each non-option argument" do
          #assert 3 because the key attribute is always present
          assert_equal 3, @dimension.attributes.length
          assert @dimension.attributes[:a]
          assert @dimension.attributes[:b]
        end
        should "pass along options to each created attribute" do
          [:a,:b].each do |attribute|
            assert_equal( { :c=>:d, :e=>:f}, @dimension.attributes[attribute].options )
          end
        end
      end

      context "#sort" do
        setup do
          @dimension.sort :s, :option=>true
        end
        should "set the sort property to the provided value" do
          assert_equal :s, @dimension.sort
        end
        should "create an attribute for the sort key if not present" do
          assert @dimension.attributes[:s]
        end
        should "pass options to the created attribute" do
          assert_equal({ :option=>true }, @dimension.attributes[:s].options)
        end
        should "return the key if no sort is defined" do
          @dimension.sort = nil
          assert_equal @dimension.key, @dimension.sort
        end
        should "not re-create a pre-existing attribute" do
          @dimension.sort :s, :option=>false
          assert_equal( { :option => true},  @dimension.attributes[:s].options )
        end
      end

      context "#caption" do
        setup do
          @dimension.caption :c, :option=>true
        end
        should "set the caption property to the provided value" do
          assert_equal :c, @dimension.caption
        end
        should "create an attribute for the caption key if not present" do
          assert @dimension.attributes[:c]
        end
        should "pass options to the created attribute" do
          assert_equal({ :option=>true }, @dimension.attributes[:c].options)
        end
        should "return the key if no caption is defined" do
          @dimension.caption = nil
          assert_equal @dimension.key, @dimension.caption
        end
        should "not re-create a pre-existing attribute" do
          @dimension.caption :c, :option=>false
          assert_equal( { :option => true},  @dimension.attributes[:c].options )
        end
      end

      context "#key" do
        setup do
          @dimension.key :k, :option=>true
        end
        should "set the key property to the provided value" do
          assert_equal :k, @dimension.key
        end
        should "create an attribute for the key if not present" do
          assert @dimension.attributes[:k]
        end
        should "pass options to the created attribute" do
          assert_equal({ :option=>true }, @dimension.attributes[:k].options)
        end
        should "not re-create a pre-existing attribute" do
          @dimension.key :k, :option=>false
          assert_equal( { :option => true},  @dimension.attributes[:k].options )
        end
      end

    end

    context "Instance methods" do
      context "#extract" do
        setup do
          @dimension = Dimension.new(:d) {  key :a; attribute :b }
        end

        should "return a hash containing all values from the message that match the dimensions attributes" do
          assert_equal({"a" => 1, "b" => :b}, @dimension.extract({ "d" =>
                                                                   {"a"=>1,
                                                                     "b"=>:b,
                                                                     "c"=>"d",
                                                                     "f"=>0}}))
        end
        should "extract the keys from an embedded hash if present" do
          assert_equal({"a" => 1, "b" => :b}, @dimension.extract({ "d" => {"a"=>1,"b"=>:b}}))
        end
        should "extract keys from the 'from' key if specified" do
          @dimension.instance_variable_set("@from", "z")
          assert_equal({"a" => 1, "b" => :b}, @dimension.extract({ "z" => {"a"=>1,"b"=>:b}}))
        end

      end
    end



  end
end
