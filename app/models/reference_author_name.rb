# frozen_string_literal: true

class ReferenceAuthorName < ApplicationRecord
  belongs_to :reference, inverse_of: :reference_author_names
  belongs_to :author_name, inverse_of: :reference_author_names

  before_save :invalidate_reference_caches
  before_destroy :invalidate_reference_caches

  acts_as_list scope: :reference
  has_paper_trail

  private

    def invalidate_reference_caches
      reference.reload
      References::Cache::Invalidate[reference]
    end
end
