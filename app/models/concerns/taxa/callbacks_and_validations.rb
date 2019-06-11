module Taxa::CallbacksAndValidations
  extend ActiveSupport::Concern

  BIOGEOGRAPHIC_REGIONS = %w[
    Nearctic Neotropic Palearctic Afrotropic Malagasy Indomalaya Australasia Oceania Antarctic
  ]
  INCERTAE_SEDIS_IN_RANKS = %w[family subfamily tribe genus]

  included do
    validates :name, presence: true
    validates :protonym, presence: true
    validates :status, inclusion: { in: Status::STATUSES }
    validates :biogeographic_region, inclusion: { in: BIOGEOGRAPHIC_REGIONS, allow_nil: true }, if: -> { is_a?(SpeciesGroupTaxon) }
    validates :biogeographic_region, absence: true, unless: -> { is_a?(SpeciesGroupTaxon) }
    validates :incertae_sedis_in, inclusion: { in: INCERTAE_SEDIS_IN_RANKS, allow_nil: true }

    validate :current_valid_taxon_validation, :ensure_correct_name_type

    validation_scope :soft_validation_warnings do |scope|
      scope.validate :check_if_in_database_scripts_results
    end

    before_save :set_name_caches

    # Additional callbacks for when `#save_initiator` is true (must be set manually).
    # TODO: Move or remove.
    before_save { remove_auto_generated if save_initiator }
    # TODO: Move or remove.
    before_save { set_taxon_state_to_waiting if save_initiator }

    strip_attributes only: [:incertae_sedis_in, :type_taxt, :headline_notes_taxt,
      :biogeographic_region], replace_newlines: true

    strip_attributes only: [:primary_type_information, :secondary_type_information, :type_notes]

    # NOTE: Not private, see https://github.com/gtd/validation_scopes#dont-use-private-methods
    def check_if_in_database_scripts_results
      Taxa::CheckIfInDatabaseResults[self]
    end
  end

  private

    def set_name_caches
      self.name_cache = name.name
      self.name_html_cache = name.name_html
    end

    def remove_auto_generated
      self.auto_generated = false
    end

    def set_taxon_state_to_waiting
      taxon_state.review_state = TaxonState::WAITING
      taxon_state.save
    end

    def current_valid_taxon_validation
      if cannot_have_current_valid_taxon? && current_valid_taxon
        errors.add :current_valid_name, "can't be set for #{Status.plural(status)} taxa"
      end

      if requires_current_valid_taxon? && !current_valid_taxon
        errors.add :current_valid_name, "must be set for #{Status.plural(status)}"
      end
    end

    def cannot_have_current_valid_taxon?
      valid_taxon? || unavailable?
    end

    def requires_current_valid_taxon?
      synonym? || original_combination? || obsolete_combination? || unavailable_misspelling? || unavailable_uncategorized?
    end

    def ensure_correct_name_type
      return if name.is_a? name_class
      return unless name_id_changed? # Make sure taxa already in this state can be saved.
      error_message = "Rank (`#{self.class}`) and name type (`#{name.class}`) must match."
      errors.add :base, error_message unless errors.added? :base, error_message
    end
end
