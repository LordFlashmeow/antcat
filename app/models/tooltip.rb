# frozen_string_literal: true

class Tooltip < ApplicationRecord
  include Trackable

  validates :scope, :text, presence: true
  validates :key, presence: true, uniqueness: { case_sensitive: true },
    format: { with: /\A[a-zA-Z0-9._:\-]+\z/, message: "can only contain alphanumeric characters and '.-_:'" }
  validates :scope, format: { with: /\A[a-z_]+\z/, message: "can only contain lowercase letters and '_'" }

  has_paper_trail
  trackable parameters: proc { { scope_and_key: "#{scope}.#{key}" } }
end
