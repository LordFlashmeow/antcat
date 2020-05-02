# frozen_string_literal: true

class JournalQuery
  REFERENCE_COUNT_ORDER = "reference_count"

  def initialize relation = Journal.all
    @relation = relation
  end

  def includes_reference_count
    relation.left_joins(:references).group(:id).select("journals.*, COUNT(references.id) AS reference_count")
  end

  private

    attr_reader :relation
end