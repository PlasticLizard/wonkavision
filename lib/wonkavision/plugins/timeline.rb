module Wonkavision
  module Plugins
    module Timeline
      def self.all
        @@all ||= []
      end

      def self.configure(activity,options={})
        activity.ensure_wonkavision_plugin(Wonkavision::Plugins::BusinessActivity,options)
        activity.write_inheritable_attribute :timeline_milestones, []
        activity.class_inheritable_reader :timeline_milestones

        options = {
                          :timeline_field => "timeline",
                          :latest_milestone_field => "latest_milestone",
                          :event_time_key => "event_time"
        }.merge(options)

        activity.business_activity_options.merge!(options)

        activity.define_document_key(activity.timeline_field,Hash,:default=>{})
        activity.define_document_key(activity.latest_milestone_field, String, :default=>"awaiting_first_event")

        Timeline.all << activity
      end

      module ClassMethods

        def milestone(name,*args)
          timeline_milestones << event(name,*args) do |activity,event_data,event_path|
            event_time = extract_event_time(event_data,event_path)
            prev_event_time = activity[timeline_field][name]
            unless prev_event_time
              activity[timeline_field][name] = event_time
              #If the event being processed happened earlier than a previously
              #recorded event, we don't want to overwrite state of the activity, as
              #it is already more up to date than the incoming event.
              latest_ms = activity[latest_milestone_field]
              unless latest_ms &&
                             (last_event = activity[timeline_field][latest_ms]) &&
                             last_event > event_time
                update_activity(activity,event_data)
                activity[latest_milestone_field] = name
              end
              :updated
            else
              :handled #If there was a previous event time for this milestone, we will just skip this event
            end
          end
        end

        def convert_time(time)
          if (time.is_a?(Hash)) && (time.keys.include?(:date) || time.keys.include?(:time))
            time = "#{time[:date]} #{time[:time]}".strip
          end
          time ? time.to_time : nil
        end

        private
        def extract_event_time(event_data,event_path)
          convert_time(event_data.delete(event_time_key.to_s)) || Time.now.utc
        end
      end

      module Fields
        def timeline_field
          business_activity_options[:timeline_field]
        end

        def latest_milestone_field
          business_activity_options[:latest_milestone_field]
        end

        def event_time_key
          business_activity_options[:event_time_key]
        end
      end
    end
  end
end