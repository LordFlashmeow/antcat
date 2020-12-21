# frozen_string_literal: true

# Fulltext search, but not all fields.

module References
  class FulltextSearchLightQuery
    include Service

    NUM_RESULTS = 15

    attr_private_initialize :search_query

    def call
      search_results
    end

    private

      def search_results
        Reference.solr_search do
          keywords normalized_search_query do
            fields :title, :author_names_string, :suffixed_year, :stated_year, :bolton_key, :authors_for_key
            boost_fields author_names_string: 5.0
            boost_fields suffixed_year: 2.0
          end

          order_by :score, :desc
          order_by :author_names_string, :desc
          order_by :suffixed_year, :asc
          paginate page: 1, per_page: NUM_RESULTS
        end.results
      end

      def normalized_search_query
        search_query.gsub(References::FulltextSearchQuery::UNFRIENDLY_SOLR_CHARACTERS_REGEX, ' ')
      end
  end
end
