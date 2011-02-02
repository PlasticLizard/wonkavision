module Wonkavision
  module Analytics
    module Persistence
      class MongoStore < Store

        def initialize(facts)
          super(facts)
        end

        def facts_collection_name
          "wv.#{owner.name.underscore.gsub("::",".")}.facts"
        end

        def facts_collection
          Wonkavision::Mongo.database[facts_collection_name]
        end

        def aggregations_collection_name
          "wv.#{owner.name.underscore.gsub("::",".")}.aggregations"
        end

        def aggregations_collection
          Wonkavision::Mongo.database[aggregations_collection_name]
        end

        def[](document_id)
          facts_collection.find({ :_id => document_id}).to_a.pop
        end


        protected
        #Fact persistence
        def update_facts_record(record_id, data)
          query = { :_id => record_id }
          update = { "$set" => data }
          previous_facts = facts_collection.find_and_modify :query=>query, :update=>update, :upsert=>true
          current_facts = (previous_facts || {}).merge(data)
          remove_mongo_id(previous_facts, current_facts)
        end

        def insert_facts_record(record_id, data)
          query = { :_id => record_id }
          facts_collection.update(query, data, :upsert=>true)
          data
        end

        def delete_facts_record(record_id, data)
          query = { :_id => record_id }
          remove_mongo_id(facts_collection.find_and_modify(:query=>query, :remove=>true))
        end

        #Aggregation persistence
        def fetch_tuples(dimension_names=[])
          criteria = dimension_names.blank? ? {} : { :dimension_names => dimension_names }
          aggregations_collection.find(criteria).to_a
        end

        def update_tuple(data)
          aggregations_collection.update( aggregation_key(data),
                                          {"$inc" => data[:measures],
                                            "$set" => { :dimensions=>data[:dimensions]}},
                                          :upsert => true, :safe => true )
        end

        def remove_mongo_id(*documents)
          unless owner.respond_to?(:record_id) && owner.record_id.to_s == "_id"
            documents.each { |doc| doc.delete("_id")}
          end
          documents.length > 1 ? documents : documents.pop
        end

      end
    end
  end
end
