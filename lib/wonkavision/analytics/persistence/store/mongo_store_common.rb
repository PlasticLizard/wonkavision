module Wonkavision
  module Analytics
    module Persistence
	  	module MongoStoreCommon
	    	def initialize(facts)
	          super(facts)
	        end

	        def facts_collection_name
	          "wv.#{owner.name.gsub("::",".").underscore}.facts"
	        end

	        def facts_collection
	          database.collection(facts_collection_name)
	        end

	        def aggregations_collection_name
	          "wv.#{owner.name.gsub("::",".").underscore}.aggregations"
	        end

	        def aggregations_collection
	          database.collection(aggregations_collection_name)
	        end

	        def[](document_id)
	          collection.find({ :_id => document_id}).to_a.pop
	        end

	        def where(criteria)
	          collection.find(criteria).to_a
	        end

	        def each(criteria, &block)
	        	collection.find(criteria).each(&block)
	        end

	        def count(criteria={})
	          collection.find(criteria).count
	        end

	        def delete_aggregations(*filters)
	        	filters = filters.flatten
	        	raise "At least one filter must be provided to delete" if filters.empty?
	        	selector = {}
	        	append_aggregations_filters(selector, filters)
	        	collection.remove(selector.merge("$atomic"=>true))
	        end

	        def collection
	          owner <=> Wonkavision::Analytics::Aggregation ? aggregations_collection :
	            facts_collection
	        end

	        def ensure_indexes
						if owner <=> Wonkavision::Analytics::Aggregation
							create_index([[:dimension_keys,1]])
							create_index([[:dimension_names,1]])
						end
	        end

	        def purge!(criteria={})
	        	collection.remove(criteria.merge("$atomic"=>true))
	        end

	        protected

	        def find(criteria, options={})
	          collection.find(criteria,options).to_a
	        end

	        def find_and_modify(opts)
	          collection.find_and_modify(opts)
	        end

	        def update(selector,update,opts={})
	          collection.update(selector,update,opts)
	        end

	        def create_index(index)
	        	collection.create_index(index)
	        end

	        def fetch_facts(aggregation,filters,options={})
	          criteria = {}
	          append_facts_filters(aggregation,criteria,filters)
	          pagination = paginate(criteria,options)

	          find(criteria,options).tap do |facts|
	            if pagination
	              class << facts;include(Wonkavision::Analytics::Paginated);end
	              facts.initialize_pagination(pagination[:total],
	                                          pagination[:page],
	                                          pagination[:per_page])
	            end

	          end
	        end

	        def paginate(criteria,options)
	          if options[:page] || options[:per_page]
	            page = ( options.delete(:page) || 1 ).to_i
	            per_page = options.delete(:per_page) || 25
	            options[:limit] = per_page
	            options[:skip] = (page - 1) * per_page
	            {
	              :total => collection.find(criteria).count,
	              :page => page,
	              :per_page => per_page
	            }
	          end
	        end

	        #Fact persistence
	        def update_facts_record(record_id, data)
	          query = { :_id => record_id }
	          update = { "$set" => data }
	          previous_facts = find_and_modify :query=>query, :update=>update, :upsert=>true
	          current_facts = (previous_facts || {}).merge(data)
	          remove_mongo_id(previous_facts, current_facts)
	        end

	        def insert_facts_record(record_id, data)
	          query = { :_id => record_id }
	          update(query, data.merge(:_id=>record_id), :upsert=>true)
	          data
	        end

	        def delete_facts_record(record_id, data)
	          query = { :_id => record_id }
	          remove_mongo_id(find_and_modify(:query=>query, :remove=>true))
	        end

	        #Aggregation persistence
	        def fetch_tuples(dimension_names, filters, &block)
	          criteria = dimension_names.blank? ? {} : { :dimension_names => dimension_names }
	          append_aggregations_filters(criteria,filters)
	          block ? each(criteria, &block) : find(criteria)
	        end

	        def update_tuple(data, incremental = true)
	        	safe = self.respond_to?(:safe) ? self.safe : false
	        	doc = {}
	        	measure_op = incremental ? "$inc" : "$set"

	        	doc[measure_op] = data[:measures] if data[:measures]
	        	(doc["$set"] ||= {})[:dimensions] = data[:dimensions] if data[:dimensions]
	          (doc["$set"] ||= {})[:snapshot] = data[:snapshot] if data[:snapshot]

	          update( aggregation_key(data), doc, :upsert => true, :safe => safe)
	        end

	        def remove_mongo_id(*documents)
	          unless owner.respond_to?(:record_id) && owner.record_id.to_s == "_id"
	            documents.compact.each { |doc| doc.delete("_id") }
	          end
	          documents.length > 1 ? documents : documents.pop
	        end

	        private
	        def append_aggregations_filters(criteria,filters)
	          filter_hash = merge_filters(filters,true) do |filter|
	            "#{filter.member_type}s.#{filter.name}.#{filter.attribute_key(owner)}"
	          end
	          criteria.merge! filter_hash
	        end

	        def append_facts_filters(aggregation,criteria,filters)
	          filter_hash = merge_filters(filters,false) do |filter|
	            filter_name = filter.dimension? ? filter.attribute_key(aggregation) : filter.name
	            prefix =      filter_prefix_for(aggregation,filter)

	            [prefix,filter_name].compact.join(".")
	          end
	          criteria.merge! filter_hash
	        end

	        def filter_value_for(criteria_hash)
	          return criteria_hash[:eq].value if criteria_hash[:eq]
	          filter_value = {}
	          criteria_hash.each_pair do |operator,filter|
	            filter_value["$#{operator}"] = filter.value
	          end
	          filter_value
	        end

	        def filter_prefix_for(aggregation,filter)
	          if filter.dimension?
	            dimension = aggregation.find_dimension(filter.name)
	            dimension.complex? ? dimension.from : nil
	          end
	        end

	        def transform_filter_hash(filter_hash)
	          transformed = {}
	          filter_hash.each_pair do |filter_key, filter_criteria|
	            transformed[filter_key] = filter_value_for(filter_criteria)
	          end
	          transformed
	        end

	        def merge_filters(filters,apply)
	          merged = {}
	          filters.each do |filter|
	            filter_key = yield(filter)
	            mf = merged[filter_key] ||= {}
	            if mf.empty?
	              mf[filter.operator] = filter
	            elsif mf[:eq]
	              assert_compatible_filters(mf[:eq], filter)
	            elsif filter.operator == :eq
	              #eq must be the only element in the filter.
	              #Therefore, if the current filter gets along with previous filters,
	              #we'll set it as the sole component to this criteria, otherwise,
	              #an error needs to be raised
	              mf.values.each{ |existing| assert_compatible_filters(filter,existing) }
	              mf.replace(:eq => filter)
	            elsif mf[filter.operator]
	              assert_compatible_filters(mf[filter.operator], filter)
	            else
	              mf[filter.operator] = filter
	            end
	            filter.applied! if apply
	          end
	          transform_filter_hash merged
	        end

	        def assert_compatible_filters(filter1,filter2)
	          ok = (filter1.operator == filter2.operator &&
	                filter1.value == filter2.value) || filter2.matches_value(filter1.value)
	          raise "Incompatible filters used: #{filter1.inspect} and #{filter2.inspect}" unless ok
	        end
	    end
    	end
    end
end
