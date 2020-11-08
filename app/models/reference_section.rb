# frozen_string_literal: true

class ReferenceSection < ApplicationRecord
  include CleanupAndConvertTaxtColumns
  include Trackable

  TAXON_TYPES_WITH_REFERENCE_SECTIONS = %w[Family Subfamily Tribe Subtribe Genus Subgenus]

  belongs_to :taxon

  before_validation :cleanup_and_convert_taxts

  acts_as_list scope: :taxon
  has_paper_trail
  strip_attributes only: [:title_taxt, :subtitle_taxt, :references_taxt], replace_newlines: true
  trackable parameters: proc { { taxon_id: taxon_id } }

  def self.search search_query, search_type
    search_type = search_type.presence || 'LIKE'

    case search_type
    when 'LIKE'
      where(<<~SQL.squish, q: "%#{search_query}%")
        title_taxt LIKE :q
          OR references_taxt LIKE :q
          OR subtitle_taxt LIKE :q
      SQL
    when 'REGEXP'
      where(<<~SQL.squish, q: search_query)
        title_taxt REGEXP :q
          OR references_taxt REGEXP :q
          OR subtitle_taxt REGEXP :q
      SQL
    else
      raise "unknown search_type #{search_type}"
    end
  end

  private

    def cleanup_and_convert_taxts
      cleanup_and_convert_taxt_columns :references_taxt, :subtitle_taxt, :title_taxt
    end
end
