module Wonkavision
  module Analytics
    module Persistence
      class MongoStore < Store

        def initialize(facts)
          super(facts)
        end

        def collection_name
          "wv.#{facts.name.underscore.gsub("::",".")}.facts"
        end

        def collection
          Wonkavision::Mongo.database[collection_name]
        end

        def[](document_id)
          collection.find({ :_id => document_id}).to_a.pop
        end


        protected
        #Fact persistence
        def update_facts_record(record_id, data)
          query = { :_id => record_id }
          update = { "$set" => data }
          previous_facts = collection.find_and_modify :query=>query, :update=>update, :upsert=>true
          current_facts = (previous_facts || {}).merge(data)
          remove_mongo_id(previous_facts, current_facts)
        end

        def insert_facts_record(record_id, data)
          query = { :_id => record_id }
          collection.update(query, data, :upsert=>true)
          data
        end

        def delete_facts_record(record_id, data)
          query = { :_id => record_id }
          remove_mongo_id(collection.find_and_modify(:query=>query, :remove=>true))
        end

        def remove_mongo_id(*documents)
          unless facts.record_id.to_s == "_id"
            documents.each { |doc| doc.delete("_id")}
          end
          documents.length > 1 ? documents : documents.pop
        end

      end
    end
  end
end
