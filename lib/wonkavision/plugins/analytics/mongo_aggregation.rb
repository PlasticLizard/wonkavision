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

        def query(query=nil,&block)
          query ||= Wonkavision::Analytics::Query.new
          query.instance_eval(&block) if block
          query.validate!

          criteria = {}
          criteria[:dimension_names] = query.selected_dimensions unless query.all_dimensions?

          Wonkavision::Analytics::CellSet.new( self,
                                               query,
                                               data_collection.find( criteria ).to_a )
        end

      end

      module InstanceMethods

        protected

        def update(measures, method)
          selector = {
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
