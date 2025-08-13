# frozen_string_literal: true

module Fabulous
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      protected

      def request(action, params = {})
        client.request(action, params)
      end

      def paginate(action, params = {}, &block)
        page = params.delete(:page) || 1
        all_results = []
        
        loop do
          response = request(action, params.merge(page: page))
          
          if block_given?
            yield response, page
          else
            all_results.concat(extract_items(response))
          end
          
          break unless response.paginated? && page < response.page_count
          page += 1
        end
        
        block_given? ? nil : all_results
      end

      def extract_items(response)
        # Override in subclasses to extract the appropriate items
        response.data.values.first || []
      end
    end
  end
end