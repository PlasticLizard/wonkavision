require "time"

module Wonkavision
  module Analytics
    module Aggregation
      class Statistics

        attr_reader :snapshot_binding, :stats

        def initialize(snapshot_binding, &block)
          @snapshot_binding = snapshot_binding
          @stats = []
          if block
            if block.arity == 1
              block.call(self)
            else
              instance_eval(&block)
            end
          end
        end
        
        def calculate!(snapshot_time, dimension_names, dimension_keys)
          algorithms = stats.inject([]) do |accum, stat|
            accum += stat.create_algorithms(snapshot_time)
            accum
          end.sort { |a, b| a.time_window <=> b.time_window }
          biggest_window = algorithms[-1].time_window

          query = create_query(biggest_window, dimension_names, dimension_keys)
          records = aggregation.store.execute_query(query)
          records.each do |agg_record|
            if agg_record
              algorithms.each do |algo|
                time, values = record_values(algo.measure_names, agg_record)
                algo.add_record(time, values) if algo.matches?(time, values)
              end
            end
          end      
          
          algorithms.each do |algo|
            update_snapshot(dimension_names, dimension_keys, algo.calculate)
          end
        end

        def snapshot
          @snapshot_binding.snapshot
        end

        def aggregation
          @snapshot_binding.aggregation
        end
        
        def method_missing(method, *args)
          super unless Algorithm[method]
          @stats << StatDef.new(self, method, *args)
        end
       
        private

        def create_query(time_window, dimension_names, dimension_keys)
          aggregation.query(:defer=>true).
            select(dimension_names).
            where query_filter(time_window, dimension_names, dimension_keys)
        end

        def query_filter(time_window, dimension_names, dimension_keys)
          key_dim_name = snapshot_binding.snapshot_key_dimension.name

          start_time, end_time = query_range(time_window)  
          filter =  Hash[*dimension_names.zip(dimension_keys).flatten]
          filter.delete(key_dim_name.to_s)

          start_filter = MemberFilter.new key_dim_name, :operator => :gte
          end_filter = MemberFilter.new key_dim_name, :operator => :lte

          filter[start_filter] = start_time
          filter[end_filter] = end_time

          filter
        end

        def query_range(time_window)
          start_key = snapshot_binding.snapshot_key_value(time_window.start_time)
          end_key = snapshot_binding.snapshot_key_value(time_window.end_time)
          [start_key, end_key]
        end

        def prepare_measures(new_measures)
          measures = {}
          new_measures.each do |name, vals|
            measures["measures.#{name}.value"] = vals
          end
          measures
        end

        def record_values(measure_names, agg_record)
          time_idx = agg_record["dimension_names"].index(snapshot_binding.snapshot_key_dimension.name.to_s)
          time_val = agg_record["dimension_keys"][time_idx]
          time_str = time_val + case snapshot.resolution
                                when :month then "-01"
                                when :year then "-01-01"
                                else ""
                                end

          time = Time.parse(time_str) unless time.kind_of?(Time)
          agg_measures = agg_record["measures"]
          values = measure_names.inject({}) do |accum, measure_name|
            m_def = aggregation.find_measure(measure_name)
            component = m_def[:default_component] || :sum
            accum[measure_name.to_s] = get_measure(component.to_s, agg_measures[measure_name.to_s])
            accum
          end
          [time, values]
        end   

        def update_snapshot(dimension_names, dimension_keys, new_measures)
          agg_data = {
            :dimension_keys => dimension_keys,
            :dimension_names => dimension_names,
            :measures => prepare_measures(new_measures)
          }
          aggregation.store.update_aggregation(agg_data, false)
        end

        def get_measure(measure_type, measures)
          measures ||= {}
          sum = measures["sum"].to_f
          count = measures["count"].to_f
          value = case measure_type
          when "sum" then sum
          when "average" then count > 0 ? sum/count : 0.0
          else count
          end
          value
        end

      end
    end
  end
end