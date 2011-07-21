module Wonkavision
  module Analytics
    class Snapshot

      attr_reader :facts, :name, :options

      def initialize(facts, name, options = {}, &blk)
        @facts = facts
        @name = name
        @options = options
        @query = options[:query] || {}
        @event_name = options[:event_name] || "wv.#{@facts.name.gsub("::",".").underscore}.snapshot.#{name}"
        @key_name = options[:key_name]
        @key = options[:key]
        @resolution = options[:resolution]
        instance_eval &blk if blk
      end

      def query(query_hash=nil)
        query_hash ? @query = query_hash : @query
      end

      def event_name(event_name = nil)
        event_name ? @event_name = event_name : @event_name
      end

      def key_name(key_name = nil)
        return @key_name = key_name if key_name
        @key_name ||= "snapshot_#{resolution}".to_sym
      end

      def key(key = nil)
        return @key = key if key
        @key ||= case @resolution.to_s
                 when "day" then :day_key
                 when "month" then :month_key
                 when "year" then :year_key
                 else :timestamp
                 end
      end

      def resolution(resolution=nil)
        return @resolution = resolution if resolution
        @resolution ||= case @name.to_s
                        when /daily/ then :day
                        when /monthly/ then :month
                        when /yearly|annual/ then :year
                        else :day
                        end
      end

      def take!(snapshot_time, calc_options = {})
        snapshot_time = snapshot_time.to_time unless snapshot_time.kind_of?(Time)
        purge!(snapshot_time)
        @facts.store.each(query) do |facts|
          submit_snapshot(facts, snapshot_time, calc_options) if facts
        end
      end 
      
      def purge!(snapshot_time)
        @facts.aggregations.each do |agg|
          if agg_ss = agg.snapshots[@name]
            snapshot_key_name = agg_ss.snapshot_key_dimension.key
            snapshot_key_value = snapshot_key(snapshot_time)[snapshot_key_name.to_s]

            agg_ss.purge!(snapshot_key_value)
          end
        end
      end 

      private

      def submit_snapshot(facts, snapshot_time, calc_options)
        snapshot_data = prepare_snapshot(facts, snapshot_time, calc_options)
        publish snapshot_data
      end
      
      def prepare_snapshot(facts, snapshot_time, calc_options)
        calc_options[:context_time] = snapshot_time
        facts[key_name.to_s] = snapshot_key(snapshot_time)
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