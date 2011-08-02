module Wonkavision
  module Analytics
    module Aggregation
      class SnapshotBinding < AggregationSpec

        attr_reader :aggregation, :snapshot

        def initialize(name, aggregation, snapshot)
          super(name)
          @aggregation = aggregation
          @snapshot = snapshot          
          @statistics = []
        end

        def purge!(snapshot_time)
          snapshot_time = snapshot_time.to_time unless snapshot_time.kind_of?(Time)
          filter = MemberFilter.new snapshot_key_dimension.name, :value => snapshot_key_value(snapshot_time)
          @aggregation.store.delete_aggregations(filter)
        end

        def snapshot_key_name
          snapshot_key_dimension.key
        end

        def snapshot_key_value(snapshot_time)
          snap_key = Wonkavision::Analytics::Snapshot.snapshot_key(snapshot_time)
          snap_key[snapshot_key_name.to_s]
        end

        def snapshot_key_dimension
          dimensions[snapshot.key_name] || dimensions.values[0]
        end

        def statistics(&block)
          return @statistics unless block
          stats = Statistics.new(self)
          if block.arity == 1
            block.call(stats)
          else
            stats.instance_eval(&block)
          end
          @statistics << stats
          listen_for_stats
        end

        def stat_calc_event_name(new_event_name=nil)
          if new_event_name
            @stat_calc_event_name = new_event_name
          elsif @stat_calc_event_name.nil?
            aggregation_name = aggregation.name.gsub("::",".")
            snap_name = snapshot.name
            my_name = name
            @stat_calc_event_name = "wv.#{aggregation_name}.#{snap_name}.#{my_name}.stats"
          end 
          @stat_calc_event_name       
        end

        def calculate_statistics!(snapshot_time)
          snapshot_time = snapshot_time.to_time unless snapshot_time.kind_of?(Time)
          key_name = "dimensions.#{snapshot.key_name}.#{snapshot_key_name}"
          key_value = snapshot_key_value(snapshot_time)
          query = {
             key_name => key_value,
             "snapshot" => snapshot.name 
          }
          aggregation.store.each(query) do |snap_record|
            submit_stat_snap(snapshot_time, snap_record) if snap_record
          end              
        end

        def submit_stat_snap(snapshot_time, snap_record)
          snapshot_data = {
            :snapshot_time => snapshot_time,
            :dimension_names => snap_record["dimension_names"],
            :dimension_keys => snap_record["dimension_keys"]
          }
          publish snapshot_data
        end
        
        def publish(snapshot_data)
          Wonkavision.event_coordinator.submit_job stat_calc_event_name,
                                                   snapshot_data
        end 
        
        def listen_for_stats
          unless @listening_for_stats
            snapshot.facts.handle stat_calc_event_name do |data|
              accept_event data
            end  
            @listening_for_stats = true
          end
        end  
        
        def accept_event(snap_data)
          snap_time = snap_data["snapshot_time"].to_time
          dimension_names = snap_data["dimension_names"]
          dimension_keys = snap_data["dimension_keys"]
          statistics.each do |stats|
            stats.calculate!(snap_time, dimension_names, dimension_keys)  
          end  
        end   

      end
    end
  end

end
