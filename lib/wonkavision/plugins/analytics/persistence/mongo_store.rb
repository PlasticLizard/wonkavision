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

        def where(criteria)
          collection.find(criteria).to_a
        end

        def count(criteria={})
          collection.find(criteria).count
        end

        def collection
          owner.kind_of?(Wonkavision::Aggregation) ? aggregations_collection :
            facts_collection
        end

        def facts_for(aggregation,filters,options={})
          criteria = {}
          append_facts_filters(aggregation,criteria,filters)
          pagination = paginate(criteria,options)

          facts_collection.find(criteria,options).to_a.tap do |facts|
            if pagination
              facts.include(Wonkavision::Analytics::Paginated)
              facts.initialize_pagination(pagination[:total],
                                          pagination[:page],
                                          pagination[:per_page])
            end

          end
        end

        protected

        def paginate(criteria,options)
          if page = options.delete(:page)
            page = page.to_i
            per_page = options.delete(:per_page) || 25
            total = facts_collection.count(criteria)
            criteria[:limit] = per_page
            criteria[:skip] = (page - 1) * per_page
            {
              :total => total,
              :page => page,
              :per_page => per_page
            }
          end
        end

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
          facts_collection.update(query, data.merge(:_id=>record_id), :upsert=>true)
          data
        end

        def delete_facts_record(record_id, data)
          query = { :_id => record_id }
          remove_mongo_id(facts_collection.find_and_modify(:query=>query, :remove=>true))
        end

        #Aggregation persistence
        def fetch_tuples(dimension_names, filters)
          criteria = dimension_names.blank? ? {} : { :dimension_names => dimension_names }
          append_aggregations_filters(criteria,filters)
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

        private
        def append_aggregations_filters(criteria,filters)
          filters.each do |filter|
            filter_key = "#{filter.member_type}s.#{filter.name}.#{filter.attribute_key(owner)}"
            criteria[filter_key] = filter_value_for(filter)
            filter.applied!
          end
        end

        def append_facts_filters(aggregation,criteria,filters)
          filters.each do |filter|

            filter_name = filter.dimension? ? filter.attribute_key(aggregation) : filter.name
            prefix =      filter_prefix_for(aggregation,filter)

            filter_key =  [prefix,filter_name].compact.join(".")

            criteria[filter_key] = filter_value_for(filter)
          end
        end

        def filter_value_for(filter)
          filter.operator == :eq ? filter.value :
              { "$#{filter.operator}" => filter.value}
        end

        def filter_prefix_for(aggregation,filter)
          if filter.dimension?
            dimension = aggregation.dimensions[filter.name]
            dimension.complex? ? dimension.from : nil
          end
        end

      end
    end
  end
end
