require "time"

module Wonkavision
  module Analytics
    module Aggregation
      class Statistics

        attr_reader :snapshot_binding, :algorithm, :options, :windows

        def initialize(snapshot_binding, algorithm, options={})
          @snapshot_binding = snapshot_binding
          @algorithm = algorithm
          @options = options
          @windows = [
                      options[:windows] ||
                      options[:window]  ||
                      default_window
                     ].flatten.sort
          @measures = options[:measures] || aggregation.measures.keys
          @measures = @measures - options[:except] if options[:except]
        end

        def snapshot
          @snapshot_binding.snapshot
        end

        def aggregation
          @snapshot_binding.aggregation
        end
        
        def snapshot!(snapshot_time, dimension_names, dimension_keys)
          fields = ["time"] + @measures
          data_set = Wonkavision::Analytics::Aggregation::DataSet.new(fields)          
          query = create_query(snapshot_time, dimension_names, dimension_keys)
          aggregation.store.execute_query(query) do |agg_record|
            data_set.add_record record_values(agg_record)
          end      
          new_measures = calculate(dataset)
          update_snapshot(dimension_names, dimension_keys, new_measures)
        end

        protected
        def calculate(dataset)
          raise NotImplementedError
        end
        
        private

        def update_snapshot(dimension_names, dimension_keys, new_measures)
          raise NotImplementedError
        end

        def record_values(agg_record)
          time_idx = agg_record["snapshot_names"].index(snapshot_binding.snapshot_key_dimension.name.to_s)
          time_val = agg_record["snapshot_keys"][time_idx]
          time = Time.parse(time_val) unless time.kind_of?(Time)

          values = [time] + measure.map do |measure_name|
            agg_record["measures"][measure_name.to_s].to_f
          end
        end

        def create_query(snapshot_time, dimension_names, dimension_keys)
          aggregation.query(:defer=>true) do
            select *dimension_names
            where query_filter(snapshot_time, dimension_names, dimension_keys)
          end
        end

        def query_filter(snapshot_time, dimension_names, dimension_keys)
          start_time, end_time = query_range(snapshot_time)  
          filter =  Hash[*dimension_names.zip(dimension_keys).flatten]
          key_dim_name = snapshot_binding.snapshot_key_dimension.name

          start_filter = MemberFilter.new key_dim_name, :operator => :gt
          end_filter = MemberFilter.new key_dim_name, :operator => :lt

          filter[start_filter] = start_time
          filter[end_filter] = end_time

          filter
        end

        def query_range(snapshot_time)
          snapshot_time = snapshot_time.to_time unless snapshot_time.kind_of?(Time)
          max_window = window[-1].to_i
          units = "#{snapshot.resolution}s".to_sym
          start_time = snapshot_time.advance(units => max_window * -1)
          start_key = snapshot_binding.snapshot_key_value(start_time)
          end_key = snapshot_binding.snapshot_key_value(snapshot_time)
          [start_key, end_key]
        end

        def default_window
          case snapshot.resolution
            when :day then 30
            when :month then 3
            when :year then 2
            else 30
          end
        end
      end
    end
  end
end