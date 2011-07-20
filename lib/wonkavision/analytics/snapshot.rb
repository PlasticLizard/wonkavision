module Wonkavision
  module Analytics
    class Snapshot

      attr_reader :facts, :name, :options, :query, :event_name

      def initialize(facts, name, options = {}, &blk)
        @facts = facts
        @name = name
        @options = options
        @query = options[:query] || {}
        @event_name = options[:event_name] || "wv.#{@facts.name.gsub("::",".").underscore}.snapshot.#{name}"
        @key_name = options[:key_name] || "snapshot_time"
        instance_eval &blk if blk
      end

      def query(query_hash=nil)
        query_hash ? @query = query_hash : @query
      end

      def event_name(event_name = nil)
        event_name ? @event_name = event_name : @event_name
      end

      def key_name(key_name = nil)
        key_name ? @key_name = key_name : @key_name
      end

      def take!(snapshot_time, calc_options = {})
        raise "A snapshot time must be provided to Snapshot.take!" unless snapshot_time

        snapshot_time = snapshot_time.to_time unless snapshot_time.kind_of?(Time)
        @facts.store.each(query) do |facts|
          submit_snapshot(facts, snapshot_time, calc_options) if facts
        end
      end  

      private

      def submit_snapshot(facts, snapshot_time, calc_options)
        snapshot_data = prepare_snapshot(facts, snapshot_time, calc_options)
        publish snapshot_data
      end
      
      def prepare_snapshot(facts, snapshot_time, calc_options)
        calc_options[:context_time] = snapshot_time
        facts[key_name] = snapshot_key(snapshot_time)
        facts = @facts.apply_dynamic(facts, calc_options)
        facts
      end

      def publish(snapshot_data)
        Wonkavision.event_coordinator.submit_job( event_name, snapshot_data )
      end

      def snapshot_key(snapshot_time)
        {
          "timestamp" => snapshot_time,
          "day_key" => snapshot_time.iso8601[0..9],
          "month_key" => snapshot_time.iso8601[0..6],
          "year_key" => snapshot_time.year,
          "day_of_month" => snapshot_time.day,
          "day_of_week" => snapshot_time.wday,
          "month" => snapshot_time.month
        }
      end
    
    end
  end
end