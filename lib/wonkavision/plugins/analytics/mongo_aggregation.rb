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
        def dimension_names
          @dimension_names ||= @dimensions.keys.sort
        end

        def dimension_keys
          @dimension_keys ||= dimension_names.map do |dim|
            @dimensions[dim.to_s][self.class.dimensions[dim].key.to_s]
          end
        end


        def update(measures, method)
          selector = {
            :aggregation_type => self.class.name,
            :dimension_keys => dimension_keys,
            :dimension_names => dimension_names
          }

          inc_measures = { }
          measures.keys.each do |measure|
            inc_measures.merge! update_measure(measure.to_s, measures[measure], method)
          end

          set_dimensions = {"dimensions" => @dimensions}

          self.class.data_collection.update(selector,
                                            {"$inc" => inc_measures, "$set" => set_dimensions},
                                            :upsert => true, :safe => true)
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
