module Wonkavision
	module Analytics
		module ApiUtils
			class << self

				def query_from_params(params)
					query = Wonkavision::Analytics::Query.new

				    #dimensions
				    ["columns","rows","pages","chapters","sections"].each do |axis|
				      if dimensions = params[axis]
				        query.select( *dimensions, :axis => axis )
				      end
				    end

				    #measures
				    query.measures params["measures"] if params["measures"]

				    #filters
				    if params["filters"]
				      params["filters"].each do |filter_string|
				        member_filter = Wonkavision::Analytics::MemberFilter.parse(filter_string)
				        query.add_filter member_filter
				      end
				    end
				    query
				end

			end
		end
	end
end
