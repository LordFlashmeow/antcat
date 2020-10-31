# frozen_string_literal: true

# NOTE: "automated edits" are currently simply activities with `automated_edits`
# set to true and `user` set to a user named "AntCatBot" (`User.find 62`).

class Activity < ApplicationRecord
  include SetRequestUuid

  EDIT_SUMMARY_MAX_LENGTH = 255
  ACTIONS_BY_GROUP = {
    default: %w[
      create
      update
      destroy
    ],
    custom: %w[
      approve_all_references
      close_feedback
      close_issue
      convert_species_to_subspecies
      create_new_combination
      create_obsolete_combination
      elevate_subspecies_to_species
      execute_script
      finish_reviewing
      force_parent_change
      merge_authors
      move_items
      move_protonym_items
      reopen_feedback
      reopen_issue
      reorder_reference_sections
      reorder_history_items
      restart_reviewing
      set_subgenus
      start_reviewing
    ],
    deprecated: %w[
      reorder_taxon_history_items
    ]
  }
  ACTIONS = ACTIONS_BY_GROUP.values.flatten
  OPTIONAL_USER_TRACKABLE_TYPES = %w[Feedback User]

  self.per_page = 30 # For `will_paginate`.

  belongs_to :trackable, polymorphic: true, optional: true
  belongs_to :user, optional: true # NOTE: Only optional for a few actions.

  validates :action, inclusion: { in: ACTIONS }
  validates :user, presence: true, unless: -> { trackable_type.in?(OPTIONAL_USER_TRACKABLE_TYPES) }

  scope :filter_where, ->(filter_params) do
    results = where(nil)
    filter_params.each do |key, value|
      results = results.where(key => value) if value.present?
    end
    results
  end
  scope :most_recent_first, -> { order(id: :desc) }
  scope :non_automated_edits, -> { where(automated_edit: false) }
  scope :unconfirmed, -> { joins(:user).merge(User.unconfirmed) }
  scope :wiki_page_activities, -> { where(trackable_type: 'WikiPage') }
  scope :issue_activities, -> { where(trackable_type: 'Issue') }

  has_paper_trail
  serialize :parameters, Hash
  strip_attributes only: [:edit_summary], replace_newlines: true

  class << self
    def create_for_trackable trackable, action, user:, edit_summary: nil, parameters: {}
      create!(
        trackable: trackable,
        action: action,
        user: user,
        edit_summary: edit_summary,
        parameters: parameters
      )
    end

    def create_without_trackable action, user, edit_summary: nil, parameters: {}
      create_for_trackable nil, action, user: user, edit_summary: edit_summary, parameters: parameters
    end

    # :nocov:
    # For calling from the console.
    def execute_script_activity user, edit_summary
      raise "You must assign a user." unless user
      raise "You must include an edit summary." unless edit_summary
      create!(trackable: nil, action: :execute_script, user: user, edit_summary: edit_summary)
    end
    # :nocov:
  end

  def pagination_page activities
    index = activities.where("id > ?", id).count
    per_page = self.class.per_page
    (index + per_page) / per_page
  end
end
