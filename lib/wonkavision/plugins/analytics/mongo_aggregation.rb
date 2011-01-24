module Wonkavision
  module Plugins
    module MongoAggregation

      module ClassMethods
        def data_collection_name
          "wv.#{self.name.underscore.gsub("::",".")}.aggregations"
        end
        def data_collection
          Wonkavision::Mongo.database[data_collection_name]
        end
      end

      module InstanceMethods

        protected
        def attribute_names
          @aggregation_key ||= @attributes.keys.sort
        end


        def update(measures, method)
          selector = {
            :aggregation_type => self.class.name,
            :attributes => @attributes,
            :aggregation => attribute_names
          }

          update = {}

          measures.keys.each do |measure|
            update.merge! update_measure(measure.to_s, measures[measure], method)
          end

          puts "Wonkavision::Mongo.database['#{self.class.data_collection_name}'].update(#{selector.inspect},'$inc'=>#{update.inspect},:upsert=>true,:safe=>true)"
          self.class.data_collection.update(selector, "$inc" => update, :upsert => true, :safe => true)
          puts self.class.data_collection.find().to_a.inspect
        end

        def update_measure(measure_name, measure_value, update_method)
          sign = update_method.to_s == "reject" ? -1 : 1
          {
            "measures.#{measure_name}.count" => 1 * sign,
            "measures.#{measure_name}.sum" => measure_value * sign,
            "measures.#{measure_name}.sum2" => (measure_value * measure_value) * sign
          }
        end

      end

    end
  end
end
