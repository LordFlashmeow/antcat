# frozen_string_literal: true

# TODO: Use Solr or ElasticSearch.

module Autocomplete
  class TaxaQuery
    include Service

    NUM_RESULTS = 10
    TAXON_ID_REGEX = /^\d+ ?$/

    attr_private_initialize :search_query, [rank: nil]

    def call
      exact_id_match || search_results
    end

    private

      def exact_id_match
        return unless search_query.match?(TAXON_ID_REGEX)

        match = Taxon.find_by(id: search_query)
        [match] if match
      end

      def search_results
        taxa = Taxon.where("name_cache LIKE ? OR name_cache LIKE ?", crazy_search_query, not_as_crazy_search_query)
        taxa = taxa.where(type: rank) if rank.present?
        taxa.includes(:name, protonym: { authorship: { reference: :author_names } }).
          references(:reference_author_names).limit(NUM_RESULTS)
      end

      def crazy_search_query
        search_query.split('').join('%') + '%'
      end

      def not_as_crazy_search_query
        "%#{search_query}%"
      end
  end
end
