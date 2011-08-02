require "test_helper"

class StatisticsTest < ActiveSupport::TestCase
  context "Statistics" do
    setup do
      
      test_data = File.join $test_dir, "test_data.aggregations"
      @test_data = eval(File.read(test_data))
      
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts" end
        include Wonkavision::Analytics::Facts
        record_id :_id
        snapshot :daily, :query => {"a" => "b"} do
          resolution :month
        end
        store :hash_store
      end

      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAgg"; end
        include Wonkavision::Analytics::Aggregation
        sum :a, :b
        average :c
        store :hash_store
      end
      @agg.aggregates @facts
      @agg.snapshot :daily do
        statistics do
          rolling_average :windows => [10,3],
                          :measures => [:a,:b, :c],
                          :except => [:b]
        end  
      end


      @binding = @agg.snapshots[:daily]
      @stats = @binding.statistics[0]
     

    end

    should "initialize from constructor options" do
      assert_equal @binding, @stats.snapshot_binding
      assert_equal 1, @stats.stats.length
      assert @stats.stats[0].algorithm.name =~ /RollingAverage/
      assert_equal [3, 10], @stats.stats[0].windows
      assert_equal [:a, :c], @stats.stats[0].measures
    end

    should "provide access to the underlying facts snapshot" do
      assert_equal @binding.snapshot, @stats.snapshot  
    end
    
    should "provide access to the underlying aggregation" do
      assert_equal @agg, @stats.aggregation  
    end  
   

    context "calculate" do
      should "fetch records, apply to algorithms, and save" do
        window = Wonkavision::Analytics::Aggregation::TimeWindow.new(Time.now, 10, :days)
        @stats.expects(:create_query).with(window, [:d1, :d2],[:k1, :k2]).returns(:query)
        @agg.expects(:store).returns(StatStore.new(@test_data))
        @stats.expects(:update_snapshot).with([:d1,:d2],[:k1, :k2],{'a_3m_average' => 79.0, 'c_3m_average' => 1.0})
        @stats.expects(:update_snapshot).with([:d1,:d2],[:k1, :k2],{'a_10m_average' => 79.0, 'c_10m_average' => 1.0})
        @stats.calculate!("2011-07-27", [:d1, :d2], [:k1, :k2])
      end
    end

  
    context "create_query" do
      setup do
        @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new(Time.now,1,:days)
        @stats.expects(:query_filter).with(@time_window, [:d1, :d2], [:k1, :k2]).returns({:a=>:b})
        @query = @stats.send(:create_query, @time_window, [:d1, :d2], [:k1, :k2])
      end
      should "return a deferred query" do
        assert_equal Wonkavision::Analytics::Query, @query.class
      end
      should "have selected the supplied dimensions" do
        assert_equal [:d1, :d2], @query.selected_dimensions
      end
      should "have filtered by the returned filter" do
        assert_equal [:dimensions.a.eq(:b)], @query.filters
      end
    end

    context "query_filter" do
      setup do
        @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new("2011-07-05",5,:days)
        @stats.expects(:query_range).with(@time_window).returns([:now,:later])
        @filter = @stats.send(:query_filter,@time_window, [:d1,:d2],[:k1,:k2])      
      end
      should "include a filter condition for each dimension=>key pair" do
        assert_equal :k1, @filter[:d1]
        assert_equal :k2, @filter[:d2]  
      end      
      should "filter the date range as defined by the time window" do
        sf = :dimensions.snapshot_month.gte
        assert_equal :now, @filter[:dimensions.snapshot_month.gte]
        assert_equal :later, @filter[:dimensions.snapshot_month.lte]
      end
    end

    context "query_range" do
      setup do
        @time_window = Wonkavision::Analytics::Aggregation::TimeWindow.new("2011-07-05",2,:months)
        @start, @end = @stats.send(:query_range, @time_window)
      end
      should "resolve the start key" do
        assert_equal "2011-06", @start
      end
      should "resolve the end key" do
        assert_equal "2011-07", @end
      end
    end

    context "update_snapshot" do
      should "prepare measures and submit an update to the aggregation store" do
        @stats.expects(:prepare_measures).with({:m=>1}).returns({:a=>1})
        @stats.aggregation.store.expects(:update_aggregation).with({
          :dimension_keys => [:k1,:k2],
          :dimension_names => [:d1, :d2],
          :measures => {:a=>1}
        }, false)
        @stats.send(:update_snapshot, [:d1, :d2], [:k1, :k2], {:m=>1})
      end
    end

    context "prepare_measures" do
      should "inline a measures hash with dot notation named mesures" do
        assert_equal( {
          "measures.a.value" => 1.0,
          "measures.b.value" => 2.0
        }, @stats.send(:prepare_measures, :a=>1.0, :b=>2.0) )
      end
    end

    context "record_values" do
      setup do
        @agg_record = @test_data[0]
        @time, @values = @stats.send(:record_values, [:a,:c], @agg_record)
      end
      should "extract the time from the record" do
        assert_equal Time.parse("2011-07-01"), @time
      end
      should "extract the right measure values" do
        expected = {"a" => 60.0, "c" => 1.0 }
        assert_equal expected, @values
      end
    end
  
  end
end

