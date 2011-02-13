require "test_helper"
require File.join $test_dir, "test_aggregation.rb"


class CellSetTest < ActiveSupport::TestCase
  Query = Wonkavision::Analytics::Query
  CellSet = Wonkavision::Analytics::CellSet

  test_data = File.join $test_dir, "test_data.tuples"
  @@test_data = eval(File.read(test_data))

  context "CellSet" do
    setup do
      @aggregation = ::TestAggregation
      @query = Wonkavision::Analytics::Query.new
      @query.select :size, :shape, :on => :columns
      @query.select :color, :on => :rows
      @query.where  :dimensions.color.ne => "black"
      @cellset = CellSet.new @aggregation, @query, @@test_data
    end

    context "Public API" do
      context "#initialize" do
        should "initialize axes" do
          assert_equal 2, @cellset.axes.length
        end

        should "populate dimension members from tuples" do
          @cellset.axes.each do |axis|
            axis.dimensions.each do |dimension|
              assert dimension.members.length > 0
            end
          end
        end

        should "populate cells from tuples" do
          assert_equal @@test_data.length - 1, @cellset.length #1 record filtered out (color=black)
        end

        should "calculate a grand total" do
          assert_equal 90, @cellset.totals.cost.count
        end

      end
      context "#[]" do
        should "locate a cell based on its coordinates, specified in query order" do
          cell = @cellset[:large, :square, :red]
          assert_not_nil cell
          assert_equal ["large", "square", "red"], cell.key
          assert_equal 10, cell.cost.count
        end
        should "return an empty cell if the coordinates don't match an existing tuple" do
          assert @cellset[:large,:octagon,:red].empty?
        end

      end
      context "#length" do
        should "return the number of total tuples in the set" do
          assert_equal @@test_data.length - 1, @cellset.length #1 record filtered out (color = black)
        end
      end
    end
    context "Implementation" do
      context "#process_tuples" do
        setup do
          @dims = @cellset.send(:process_tuples, @@test_data)
        end
        context "processed cells" do
          should "contain one entry for each matching tuple" do
            assert_equal @@test_data.length - 1, @cellset.cells.length #1 record are black, and filtered
          end
          should "be keyed by a query-ordered array of dimension keys" do
            test_key = @cellset.cells.keys.find { |key|key - ["red", "square", "large"] == []}
            assert_equal ["large", "square", "red"], test_key
          end
        end
        context "processed dimension members" do
          should "contain one entry for each dimension" do
            assert_equal 3, @dims.length
            @query.selected_dimensions.each { |dim| assert @dims.keys.include?(dim.to_s)}
          end
          should "provide a hash of members for the dimensions" do
            test_dim = @dims["color"]
            %w(red green yellow white).each do |mem_key| #black is filtered out
              assert test_dim.keys.include?(mem_key)
            end
          end
          should "include the dimension attributes in the member hash" do
            test_dim = @dims["color"]
            assert_equal( { "color" => "red" }, test_dim["red"] )
          end
        end
      end
      context "#key_for" do
        setup do
          @record = {
            "dimension_keys"=>["yellow", "square", "small"],
            "dimension_names"=>["color", "shape", "size"] }
        end
        should "re-order the dimension_keys array to match query order" do
          assert_equal ["small", "square", "yellow"], @cellset.send(:key_for,
                                                                    @query.selected_dimensions,
                                                                    @record)
        end
      end
      context "Support Classes" do
        context "Axis" do
          setup {  @axis = @cellset.columns }
          context "#initialize" do
            should "initialize a Dimension object for each dimension" do
              assert_equal 2, @axis.dimensions.length
            end
            should "order dimensions in query order" do
              assert_equal "size", @axis.dimensions[0].name
              assert_equal "shape", @axis.dimensions[1].name
            end
            should "calculate appropriate start and end indexes" do
              assert_equal 0, @axis.start_index
              assert_equal 1, @axis.end_index
              assert_equal 2, @cellset.rows.start_index
              assert_equal 2, @cellset.rows.end_index
            end
          end
          context "#[]" do
            setup do
              @cell = @axis[:large,:circle]
            end
            should "locate a totals cell for the given coordinates" do
              assert_not_nil @cell
            end
            should "locate a cell with an abbreviated key matching just the axis coords" do
              assert_equal ["large", "circle"], @cell.key
            end
            should "locate a cell with correctly specified dimensions" do
              assert_equal [:size,:shape], @cell.dimensions
            end
            should "aggregate all detail for the given summary cell" do
              assert_equal 20, @cell.cost.count
            end
            should "aggregate detail for each dimension in the axis" do
              assert_equal 30, @axis[:large].cost.count
              assert_equal ["large"], @axis[:large].key
              assert_equal [:size], @axis[:large].dimensions
            end
          end

        end
        context "Dimension" do
          setup { @dimension = @cellset.columns.dimensions[0] }
          context "#initialize" do
            should "should return #name" do
              assert_equal "size", @dimension.name
            end
            should "extract its definition from the aggregation" do
              assert_equal @aggregation.dimensions["size"], @dimension.definition
            end
            should "should contain a sorted list of members" do
              %w(large medium small).each_with_index do |size,idx|
                assert_equal size, @dimension.members[idx].key
              end
            end
          end
        end
        context "Member" do
          setup {  @member = @cellset.columns.dimensions[0].members[0]}
          should "maintain a reference to its parent dimension" do
            assert_equal @cellset.columns.dimensions[0], @member.dimension
          end
          should "provide named access to the main dimension attributes" do
            assert_equal "large", @member.caption
            assert_equal "large", @member.key
            assert_equal "large", @member.sort
          end
          should "provide access to the raw attribute hash" do
            assert_equal( { "size" => "large"}, @member.attributes )
          end
        end
        context "Cell" do
          setup {  @cell = @cellset[:large, :square, :red] }
          should "provide access to the cell key" do
            assert_equal ["large", "square", "red"], @cell.key
          end
          should "include a hash of measures" do
            %w(cost weight).each { |measure| assert @cell.measures.keys.include?(measure)}
          end
          should "provide named access to each measure" do
            assert_equal @cell.measures["cost"], @cell.cost
            assert_equal @cell.measures["weight"], @cell.weight
          end
          should "return an empty measure if no measure exists" do
            assert @cell.a_non_existent_member.empty?
          end
          context "#aggregate" do
            setup do
              @cell.aggregate({"cost"=>{ "count"=>1,"sum"=>1,"sum2"=>2},
                                "different"=>{ "count"=>2,"sum"=>2,"sum2"=>8}})

            end
            should "insert any new measures" do
              assert @cell.measures.keys.include?("different")
            end
            should "aggregate data from an existing measure" do
              assert_equal 11, @cell.cost.count
              assert_equal 51, @cell.cost.sum
              assert_equal 252, @cell.cost.sum2
            end
            should "maintain a reference to the dimensions represented by the cell" do
              assert_equal [:size,:shape,:color], @cell.dimensions
            end
            should "maintain a reference to the cell key" do
              assert_equal ["large", "square", "red"], @cell.key
            end
          end
          context "#filters" do
            setup do
              @query.where :dimensions.another.caption.gt => 5
            end
            should "include one filter for each component of the cell" do
              expected = [:dimensions["size"].key.eq('large'),
                          :dimensions["shape"].key.eq('square'),
                          :dimensions["color"].key.eq('red'),
                          :dimensions["another"].caption.gt(5)]
             assert_equal expected, @cell.filters
            end

          end
        end

        context "Measure" do
          setup { @measure = @cellset[:large, :square, :red].cost }
          should "provide access to its name" do
            assert_equal "cost", @measure.name
          end
          should "provide access to the measure hash" do
            assert_equal( {"count"=>10, "sum"=>50, "sum2"=>250}, @measure.data )
          end
          should "provide named hash to measure values" do
            assert_equal 10, @measure.count
            assert_equal 50, @measure.sum
            assert_equal 250, @measure.sum2
          end
          should "calculate an average" do
            assert_equal 5, @measure.average
          end
          context "#aggregate" do
            setup do
              @measure.aggregate(@measure.data.dup)
            end
            should "add sum, sum2 and count to the existing values" do
              assert_equal 20, @measure.count
              assert_equal 100, @measure.sum
              assert_equal 500, @measure.sum2
            end
          end
          context "when empty" do
            should "say it is empty" do
              assert Wonkavision::Analytics::CellSet::Measure.new(:hi,{}).empty?
            end
            should "say it is empty when the count is 0" do
              assert Wonkavision::Analytics::CellSet::Measure.new(:hi,{"count"=>0}).empty?
            end
            should "return null for sum, sum2 and average" do
              cell = Wonkavision::Analytics::CellSet::Measure.new(:hi,
                                                                  { "count"=>0,
                                                                    "sum"=>100,
                                                                    "sum2"=>1000})
              assert_nil cell.sum
              assert_nil cell.sum2
              assert_nil cell.average
            end
          end
          context "formatting and defaults" do
            setup do
              @m1 = @cellset[:large, :square, :red].weight
              @m2 = @cellset[:large, :square, :red].cost
            end
            should "return the default aggregation component when asked for a value" do
              assert_equal @m1.average, @m1.value
              assert_equal @m2.sum, @m2.value
            end
            should "return the formatted_value using the requested format" do
              assert_equal "1.00", @m1.formatted_value
              assert_equal "50.0", @m2.formatted_value
            end
            should "use formatted value for #to_s" do
              assert_equal @m1.formatted_value, @m1.to_s
            end
            should "use raw value for inspect" do
              assert_equal @m1.value, @m1.inspect
            end
          end

        end

      end
    end
  end
end
