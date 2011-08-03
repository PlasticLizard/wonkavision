module Wonkavision
  module Analytics
    module Paginated
      attr_reader :total_entries, :current_page, :per_page

      def initialize_pagination(total, page, per_page=nil)
        @total_entries = total.to_i
        @current_page  = [page.to_i, 1].max
        @per_page      = (per_page || 25).to_i
      end

      def pagination_data
        {
          :total_entries => total_entries,
          :current_page => current_page,
          :per_page => per_page
        }
      end
      
    end
  end
end
