require "test_helper"

class MapTest < ActiveSupport::TestCase
  context "Map.initialize" do
    should "make the provided object the current context" do
      assert_equal 1, Wonkavision::MessageMapper::Map.new(1).context
    end
  end
  context "Indexing into a MicroMapper::Map" do
    should "provide indifferent access" do
      h = Wonkavision::MessageMapper::Map.new({})
      h[:hello] = "hi"
      assert_equal "hi", h["hello"]
      h["hi"] = {:hello=>:sir}
      assert_equal({:hello=>:sir}, h[:hi])
    end
    should "allow method missing to index into hash" do
      l = Wonkavision::MessageMapper::Map.new({})
      l.hello = "goodbye"
      assert_equal "goodbye", l[:hello]
      assert_equal "goodbye", l.hello
    end
  end
  context "Map.from" do
    should "evaluate the provided block against the map using the provided object as the current context" do
      m = Wonkavision::MessageMapper::Map.new({})
      m.from(1) do
        self.take_it = context
      end
      assert_equal 1, m.take_it
    end
    should "return the previous context after the block" do
      m = Wonkavision::MessageMapper::Map.new(1)
      m.from(2) do
        self.a = context
      end
      assert_equal 1, m.context
      assert_equal 2, m.a
    end
  end
  context "Map.map" do
    should "raise an exception if called without a block or map name" do
      m = Wonkavision::MessageMapper::Map.new({})
      assert_raise RuntimeError do
        m.child(1)
      end
    end
    should "eval a provided block against a new map with the provided context" do
      m = Wonkavision::MessageMapper::Map.new({})
      ctx = {:hi=>true}
      m.child "this"=>ctx do
        self.ctx = context
      end
      assert_equal ctx, m.this.ctx
    end
    should "execute the provided map_name using the provided context" do
      Wonkavision::MessageMapper.register("map_test") do
        self.ctx = context
      end
      m = Wonkavision::MessageMapper::Map.new({})
      ctx = {:hi=>true}
      m.child({"this"=>ctx}, {:map_name=>"map_test"})
      assert_equal ctx, m.this.ctx
    end
    should "Get the context based on provided field name" do
      m = Wonkavision::MessageMapper::Map.new({:a=>:b})
      m.child "length" do
        self.l = context
      end
      assert_equal 1,m["length"].l
    end
  end
  context "Map.string" do
    should "convert the underlying value to a string" do
      m = Wonkavision::MessageMapper::Map.new({:a=>:b})
      m.string :a
      assert_equal "b", m.a
    end
  end
  context "Map.float" do
    should "convert the underlying value to a float" do
      m = Wonkavision::MessageMapper::Map.new({:a=>"1"})
      m.float :a
      assert_equal 1.0, m.a
    end
  end
  context "Map.iso8601" do
    should "convert underlying dates into an iso 8601 string" do
      m = Wonkavision::MessageMapper::Map.new({:a=>Time.parse("02/01/2001 01:00 PM")})
      m.iso8601 :a
      assert_equal "2001-02-01T13:00:00", m.a
    end
  end
  context "Map.date" do
    should "convert a string to a date" do
      m = Wonkavision::MessageMapper::Map.new({:a=>"01/02/2001"})
      m.date :a
      assert_equal "01/02/2001".to_time, m.a
    end
    should "accept a date unmolested" do
      m = Wonkavision::MessageMapper::Map.new(:a=>Date.today)
      m.date :a
      assert_equal Date.today, m.a
    end
    should "accept a time unmolested" do
      time = Time.now
      m = Wonkavision::MessageMapper::Map.new(:a=>time)
      m.date :a
      assert_equal time, m.a
    end
  end
  context "Map.boolean" do
    should "convert a 'true' string to a bool" do
      m = Wonkavision::MessageMapper::Map.new(:a=>'TruE')
      m.boolean :a
      assert m.a
    end
    should "convert a 'yes' string a bool" do
      m = Wonkavision::MessageMapper::Map.new(:a=>'YeS')
      m.boolean :a
      assert m.a
    end
    should "convert any other string to a false" do
      m = Wonkavision::MessageMapper::Map.new(:a=>"Whatever")
      m.boolean :a
      assert_equal false, m.a
    end
    should "accept a proper boolean at face value" do
      m = Wonkavision::MessageMapper::Map.new(:a=>true)
      m.boolean :a
      assert m.a
    end
  end
  context "Map.int" do
    should "convert a value to an int" do
      m = Wonkavision::MessageMapper::Map.new(:a=>"5.2")
      m.int :a
      assert_equal 5, m.a
    end
  end
   context "Map.dollars" do
    should "convert to a dollar string" do
      m= Wonkavision::MessageMapper::Map.new(:a=>"5.2")
      m.dollars :a
      assert_equal "$5.20", m.a
    end
  end
  context "Map.percent" do
    should "convert to a percent string" do
      m = Wonkavision::MessageMapper::Map.new(:a=>"5")
      m.percent :a
      assert_equal "5.0%", m.a
    end
  end
  context "Map.yes_no" do
    should "convert a bool into a Yes or No" do
      m = Wonkavision::MessageMapper::Map.new(:a=>true, :b=>false)
      m.yes_no :a,:b
      assert_equal "Yes", m.a
      assert_equal "No", m.b
    end
  end
  context "Map.exec" do
    setup do
      Wonkavision::MessageMapper.register "exec_test" do
        string :len => context.length
      end
    end
    should "apply an external map to the current context" do
      m = Wonkavision::MessageMapper::Map.new([1,2,3])
      m.exec "exec_test"
      assert_equal "3", m.len
    end
    should "apply an external map to a supplied context" do
      m = Wonkavision::MessageMapper::Map.new([1,2,[1,2,3,4]])
      m.exec "exec_test", m.context[-1]
      assert_equal "4", m.len
    end
  end
  context "Map.value" do
    context "when the only argument is a hash" do
      should "iterate the hash, mapping each entry" do
        context = {:a=>1, :b=>2}
        m = Wonkavision::MessageMapper::Map.new(context)
        m.value :c=>context[:a], :d=>context[:b]
        assert_equal 1, m.c
        assert_equal 2, m.d
      end
      should "evaluate a proc in the context of a proc if provided" do
        m = Wonkavision::MessageMapper::Map.new(:a=>1)
        m.value :c=> proc {self[:a]}
        assert_equal 1, m.c
      end
      should "evaluate a block in the context of the provided value" do
        m = Wonkavision::MessageMapper::Map.new(:a=>1)
        m.value(:c=>m.context) do
          self[:a]
        end
        assert_equal 1, m.c
      end
      should "format numbers via a provided format string" do
        m = Wonkavision::MessageMapper::Map.new(:a=>"1")
        m.value(:a, :format=>"%.1f")
        assert_equal "1.0", m.a
      end
      should "format dates via a provided format string" do
        m = Wonkavision::MessageMapper::Map.new(:a=>Date.today)
        m.value(:a, :format=>"%Y-%m-%d %H:%M:%S")
        assert_equal Date.today.strftime("%Y-%m-%d %H:%M:%S"), m.a
      end
      should "format a value as a float if precision is specified" do
        m = Wonkavision::MessageMapper::Map.new(:a=>"3")
        m.value(:a, :precision=>2)
        assert_equal "3.00", m.a
      end
      should "format dollars as dollars" do
        m = Wonkavision::MessageMapper::Map.new(:a=>"3.1")
        m.value(:a, :format=>:dollars)
        assert_equal "$3.10", m.a
      end
      should "repsect precision option for dollars" do
        m = Wonkavision::MessageMapper::Map.new(:a=>"3.1")
        m.value(:a, :format=>:dollars, :precision=>1)
        assert_equal "$3.1", m.a
      end
      should "format percents" do
        m= Wonkavision::MessageMapper::Map.new(:a=>"3.12")
        m.value(:a, :format=>:percent)
        assert_equal "3.1%", m.a
      end
      should "format yes_no = yes correctly" do
        m = Wonkavision::MessageMapper::Map.new(:a=>true)
        m.value(:a, :format=>:yes_no)
        assert_equal "Yes", m.a
      end
      should "format yes_no = no correctly" do
        m = Wonkavision::MessageMapper::Map.new(:a=>false)
        m.value(:a, :format=>:yes_no)
        assert_equal "No", m.a
      end
    end
    context "when called with a list of names" do
      should "iterate the list, mapping each entry" do
        m = Wonkavision::MessageMapper::Map.new(:a=>1, :b=>2)
        m.value :a, :b
        assert_equal 1, m.a
        assert_equal 2, m.b
      end
      should "call a method by the same name on the context if present" do
        m = Wonkavision::MessageMapper::Map.new("01/01/2001")
        m.value :to_time
        assert_equal "01/01/2001".to_time, m.to_time
      end
      should "index into a hash if provided" do
        m = Wonkavision::MessageMapper::Map.new(:a=>1)
        m.value :a
        assert_equal 1, m.a
      end
      should "evaluate a block on the value if provided" do
        m = Wonkavision::MessageMapper::Map.new(:a=>1)
        m.value(:a) {to_s}
        assert_equal "1", m.a
      end
    end
    context "when mapping an array" do
      should "apply the supplied block to each item in the array" do
        m = Wonkavision::MessageMapper::Map.new(:collection=>[{:a=>1,:b=>2},{:a=>3,:b=>4}])
        m.array :collection do
          string :a
          integer :b
        end
        assert_equal 2, m.collection.length
        assert_equal "1", m.collection[0].a
        assert_equal 2, m.collection[0].b
        assert_equal "3", m.collection[1].a
        assert_equal 4, m.collection[1].b
      end
    end
  end
end