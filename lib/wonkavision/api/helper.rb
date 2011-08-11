module Wonkavision
  module Api
    class Helper

      LIST_DELIMITER = "|"
      
      def initialize(namespace=nil)
        @namespace = namespace
      end

      def constantize(name)
        class_name = @namespace ? "#{@namespace}::#{name}" : name
        class_name.constantize
      end
      
      def query_from_params(params)
        query = Wonkavision::Analytics::Query.new

        #dimensions
        ["columns","rows","pages","chapters","sections"].each do |axis|
          if dimensions = parse_list(params[axis])
            query.select( *dimensions, :axis => axis )
          end
        end

        #measures
        query.measures parse_list params["measures"] if params["measures"]

        #filters
        filters = parse_filters(params["filters"])
        filters.each do |member_filter|
          query.add_filter member_filter
        end

        query.snapshot params["snapshot"] if params["snapshot"]
        
        query
      end

      def execute_query(params)
        aggregation = constantize(params[:aggregation])
        query = query_from_params(params)
        aggregation.execute_query(query).serializable_hash
      end

      def facts_for(params)
        aggregation = constantize(params[:aggregation])
        filters, options = facts_query_from_params(params)
        facts_data = aggregation.facts_for(filters, options)
        response = {
          :facts_class => aggregation.facts.name.split("::").pop,
          :data => facts_data
        }
        if facts_data.kind_of?(Wonkavision::Analytics::Paginated)
          response[:pagination] = facts_data.pagination_data
        end
        response
      end

      def purge(params)
        facts = constantize(params[:facts])
        purge_snapshots = !!params[:purge_snapshots]
        facts.purge!(purge_snapshots)
      end

      def take_snapshot(params)
        facts = constantize(params[:facts])
        snap = facts.snapshots[params[:snapshot].to_sym]
        time = Time.parse(params[:snapshot_time])
        snap.take! time
      end

      def calculate_statistics(params)
        facts = constantize(params[:facts])
        snap = facts.snapshots[params[:snapshot].to_sym]
        time = Time.parse(params[:snapshot_time])
        snap.calculate_statistics! time
      end
     
      def facts_query_from_params(params)
        filters = parse_filters(params["filters"])
        options = {}
        options[:page] = params["page"].to_i if params["page"]
        options[:per_page] = params["per_page"].to_i if params["per_page"]
        options[:sort] = parse_sort_list(params["sort"]) if params["sort"]
        [filters, options]
      end

      def parse_filters(filters_string)
        filters = parse_list(filters_string) || []
        filters.map{ |f| Wonkavision::Analytics::MemberFilter.parse(f) }
      end

      def parse_sort_list(sort_string)
        sort = parse_list(sort_string) || []
        sort.map{ |s| parse_sort(s) }  
      end

      def parse_sort(sort_string)
        sort = sort_string.split(":")
        if sort.length > 1
          sort[1] = sort[1].to_i
        else
          sort << 1
        end  
        sort
      end

      def parse_list(list_candidate)
        return nil if list_candidate.blank?
          list_candidate.kind_of?(Array) ? 
            list_candidate :
            list_candidate.to_s.split(LIST_DELIMITER).map{|item|item.strip}.compact
      end

    end
  end
end
