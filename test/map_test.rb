require "test_helper"

class MapTest < ActiveSupport::TestCase
  context "Map.initialize" do
    should "make the provided object the current context" do
      assert_equal 1, Wonkavision::MessageMapper::Map.new(1).context
    end
  end
  context "Indexing into a MessageMapper::Map" do
    should "provide indifferent access" do
      h = Wonkavision::MessageMapper::Map.new({})
      h[:hello] = "hi"
      assert_equal "hi", h["hello"]
      h["hi"] = {:hello=>:sir}
      assert_equal({:hello=>:sir}, h[:hi])
    end

    should "provide indifferent deletes" do
      h = Wonkavision::MessageMapper::Map.new({})
      h["hello"] = "hi"
      assert_equal "hi", h.delete(:hello)
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
    should "provide access to the parent context" do
      m = Wonkavision::MessageMapper::Map.new(1)
      m.from(2) do
        self.a = context(-1)  
      end
      assert_equal 1, m.a
    end
  end
  context "Map.child" do
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
    should "provide access to the parent context" do
      m = Wonkavision::MessageMapper::Map.new({:a=>:b})
      m.child "length" do
        int :times_two => context * 2
        from context(-1) do
          string :a
        end
      end
      assert_equal 2, m["length"]["times_two"]
      assert_equal( "b", m["length"]["a"] )
    end
  end
  context "Map.remove" do
    should "Allow a key to be removed" do
      m = Wonkavision::MessageMapper::Map.new({:a=>:b, :c=>:d})
      m.string :a, :c
      assert m.keys.include?("a")
      m.remove(:a)
      assert !m.keys.include?("a")
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
      assert_equal Time.parse("02/01/2001 01:00 PM").iso8601[0..-7], m.a
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
      m.time :a
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
      m= Wonkavision::MessageMapper::Map.new(:a=>"100255.2")
      m.dollars :a
      assert_equal "$100,255.20", m.a
    end
  end
  context "Map.percent" do
    should "convert to a percent string" do
      m = Wonkavision::MessageMapper::Map.new(:a=>"5")
      m.percent :a
      assert_equal "500.0%", m.a
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
      should "return nil when a formatted date is requested on a nil value" do
        m = Wonkavision::MessageMapper::Map.new(:a=>nil)
        m.date(:a, :format=>"%Y")
        assert_nil m.a
      end
      should "use the provided default is the mapped value is nil" do
        m = Wonkavision::MessageMapper::Map.new(:a=>nil)
        m.value(:a, :precision=>2, :default=>1)
        assert_equal "1.00", m.a
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
        m= Wonkavision::MessageMapper::Map.new(:a=>"3.1212")
        m.value(:a, :format=>:percent)
        assert_equal "312.1%", m.a
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
      should "append prefix and suffix to keys when provided" do
        m = Wonkavision::MessageMapper::Map.new(:a=>false)
        m.value(:a, :format=>:yes_no, :prefix=>"pre_", :suffix=>"_post")
        assert_equal "No", m.pre_a_post
        assert_nil m.a
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
    context "Map.array" do
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
      should "apply the supplied block to each item in the explicitly provided array" do
        m = Wonkavision::MessageMapper::Map.new(:collection=>[{:a=>1,:b=>2},{:a=>3,:b=>4}])
        m.array :new_collection=>m.context[:collection] do
          string :a
          integer :b
        end
        assert_equal 2, m.new_collection.length
        assert_equal "1", m.new_collection[0].a
        assert_equal 2, m.new_collection[0].b
        assert_equal "3", m.new_collection[1].a
        assert_equal 4, m.new_collection[1].b
      end
      should "provide access to the parent context" do
        m = Wonkavision::MessageMapper::Map.new(:c => [1,2])
        m.array :c2 => m.context[:c] do
          int :a => context
          value :c => context(-1)[:c]
        end
        assert_equal [{"a"=>1, "c"=>[1,2]},{"a"=>2, "c"=>[1,2]}], m.c2

      end
      should "respect a predicate" do
        m = Wonkavision::MessageMapper::Map.new(:c => [1,2,3])
        m.array :c, :if => proc { |item| item % 2 != 0 } do
          int :me => context
        end
        assert_equal [{"me" => 1},{"me" => 3}], m.c
      end
    end

    context "Map.duration" do
      should "return nil if no :from or :to value is available" do
        m = Wonkavision::MessageMapper::Map.new
        m.duration :a_duration
        assert_nil m.a_duration
      end
      should "return time from Time.now if only to is supplied" do
        m = Wonkavision::MessageMapper::Map.new({ :a => "1/1/2001" })
        m.time :a
        m.duration :a_duration, :to => m.a
        assert m.a_duration < 0
      end
      should "return time to Time.now if only from is supplied" do
        m = Wonkavision::MessageMapper::Map.new({ :a=>"1/1/2001"})
        m.time :a
        m.duration :a_duration, :from => m.a
        assert m.a_duration > 0
      end
      should "return nil if from and to are supplied, but to is nil" do
        m = Wonkavision::MessageMapper::Map.new({ :a=>"1/1/2001", :b=>nil})
        m.time :a
        m.time :b
        m.duration :a_duration, :from => m.a, :to => m.b
        assert_nil m.a_duration
      end
      should "convert the duration to the desired time unit" do
        m = Wonkavision::MessageMapper::Map.new
        m.expects(:convert_seconds).with(1,:months)
        m.time :a=>"1/1/2001 00:00:00"
        m.time :b=>"1/1/2001 00:00:01"
        m.duration :a_duration, :from=>m.a, :to=>m.b, :in=>:months
      end
    end
    context "Map.convert_seconds" do
      setup do
        @m = Wonkavision::MessageMapper::Map.new
      end
      should "raise an exception for an invalid unit" do
        assert_raise(RuntimeError) { @m.send(:convert_seconds,1,:wakka)}
      end
      should "correctly calculate proper units" do
        assert_equal 100, @m.send(:convert_seconds,100,:seconds)
        assert_equal 1, @m.send(:convert_seconds,60,:minutes)
        assert_equal 1, @m.send(:convert_seconds,60*60,:hours)
        assert_equal 1, @m.send(:convert_seconds,60*60*24,:days)
        assert_equal 1, @m.send(:convert_seconds,60*60*24*7,:weeks)
        assert_equal 1, @m.send(:convert_seconds,60*60*24*30,:months)
        assert_equal 1, @m.send(:convert_seconds,60*60*24*365,:years)
      end

    end
    
    context "Map.date_dimension" do
      setup do
        @m = Wonkavision::MessageMapper::Map.new ({"date_field" => "2011-07-01"}) 
      end
      should "create a child with expanded date properties" do
        @m.date_dimension :date_field
        expected = {
          "timestamp" => "2011-07-01".to_time,
          "day_key" => "2011-07-01",
          "month_key" => "2011-07",
          "year_key" => "2011",
          "day_of_month" => 1,
          "day_of_week" => 5,
          "month" => 7
        }
        assert_equal expected, @m.date_field
      end
    end
    
    context "Map.lookup" do
      setup do
        @m = Wonkavision::MessageMapper::Map.new(
          {:my=>:data}, :lookup => proc { |from, id| {from => id} }
        )
      end
      should "call the proc with the given args and return the result" do
        assert_equal( {:this => :that}, @m.lookup(:this, :that) )
      end
      should "be able to compose child and lookup" do
        @m.child :this_that => @m.lookup(:this, :that) do
          string :this
        end
        assert_equal "that", @m.this_that["this"]
      end
      context "Map.lookup_child" do
        should "create a child, using the result of the lookup as the child context" do
          @m.lookup_child :this_that, :this, :that do
            string :this
          end
          assert_equal "that", @m.this_that["this"]
        end
      end
    end


  end
end
