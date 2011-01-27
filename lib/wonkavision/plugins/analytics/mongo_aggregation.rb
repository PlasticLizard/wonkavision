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

          self.class.data_collection.update(selector, {"$inc" => update}, :upsert => true, :safe => true)
        end

        def update_measure(measure_name, measure_value, update_method)
          sign = update_method.to_s == "reject" ? -1 : 1
          {
            "measures.#{measure_name}.count" => 1 * sign,
            "measures.#{measure_name}.sum" => measure_value * sign,
            "measures.#{measure_name}.sum2" => (measure_value * measure_value) * sign
          }
        end

        #Target storage format
        # aggregation = self.class.name
        # dimension_names = ["one","two","three"]
        # dimensions = {"one"=>{"sortf"=>"a","captf"=>"b","keyf"=>"c"}, "two"=>{"sortf"=>1,"keyf"=>"x"}}
        # measures = {...}

      end

    end
  end
end
