require 'references/reference_has_document'
require 'references/reference_search'
require 'references/reference_utility'
require 'references/reference_workflow'

class Reference < ActiveRecord::Base
  include UndoTracker

  attr_accessor :publisher_string
  attr_accessor :journal_name
  has_paper_trail meta: { change_id: :get_current_change_id }

  attr_accessible :citation_year,
                  :title,
                  :journal_name,
                  :series_volume_issue,
                  :publisher_string,
                  :pages_in,
                  :nesting_reference_id,
                  :citation,
                  :document_attributes,
                  :public_notes,
                  :editor_notes,
                  :taxonomic_notes,
                  :cite_code,
                  :possess,
                  :date,
                  :author_names,
                  :author_names_suffix,
                  :pagination,
                  :review_state,
                  :doi

  before_save { |record| CleanNewlines::clean_newlines record, :editor_notes, :public_notes, :taxonomic_notes, :title, :citation }

  # associations
  has_many :reference_author_names, -> { order :position }
  has_many :groups, :through => :group_assets

  has_many :author_names,
           -> { order 'reference_author_names.position' },
           :through => :reference_author_names,
           :after_add => :refresh_author_names_caches,
           :after_remove => :refresh_author_names_caches
  belongs_to :journal
  belongs_to :publisher

  def nestees
    self.class.where(nesting_reference_id: id)
  end

  # scopes
  scope :sorted_by_principal_author_last_name, -> { order(:principal_author_last_name_cache) }
  scope :with_principal_author_last_name, lambda { |last_name| where(principal_author_last_name_cache: last_name) }

  # Other plugins and mixins
  include ReferenceComparable

  def author
    principal_author_last_name
  end

  # validation and callbacks
  before_validation :set_year_from_citation_year, :strip_text_fields
  validates :title, presence: true, if: Proc.new { |record| record.class.requires_title }

  def self.requires_title
    true
  end

  before_save :set_author_names_caches
  before_destroy :check_not_nested

  # accessors
  def to_s
    "#{author_names_string} #{citation_year}. #{id}."
  end

  def authors reload = false
    author_names(reload).map &:author
  end

  def author_names_string
    author_names_string_cache
  end

  def author_names_string=(string)
    self.author_names_string_cache = string
  end

  def principal_author_last_name
    principal_author_last_name_cache
  end

  def short_citation_year
    citation_year.gsub %r{ .*$}, ''
  end

  ## callbacks

  # validation
  def check_not_nested
    nesting_reference = NestedReference.find_by_nesting_reference_id id
    if nesting_reference
      errors.add :base, "This reference can't be deleted because it's nested in #{nesting_reference}"
    end
    nesting_reference.nil?
  end

  # update (including observed updates)
  def refresh_author_names_caches(*)
    string, principal_author_last_name = make_author_names_caches
    update_attribute :author_names_string_cache, string
    update_attribute :principal_author_last_name_cache, principal_author_last_name
  end

  ## utility
  # Called by controller to parse an input string for author names and suffix
  # Returns hash of parse result, or adds to the reference's errors and raises
  def parse_author_names_and_suffix author_names_string
    author_names_and_suffix = AuthorName.import_author_names_string author_names_string.dup
    if author_names_and_suffix[:author_names].empty? && author_names_string.present?
      errors.add :author_names_string, "couldn't be parsed. Please post a message on http://groups.google.com/group/antcat/, and we'll fix it!"
      self.author_names_string = author_names_string
      raise ActiveRecord::RecordInvalid.new self
    end
    author_names_and_suffix
  end

  def check_for_duplicate
    duplicates = DuplicateMatcher.new.match self
    return unless duplicates.present?

    duplicate = Reference.find duplicates.first[:match].id
    errors.add :base, "This may be a duplicate of #{duplicate.decorate.format} #{duplicate.id}.<br>To save, click \"Save Anyway\"".html_safe
    true
  end

  def self.citation_year_to_year citation_year
    if citation_year.blank?
      nil
    elsif match = citation_year.match(/\["(\d{4})"\]/)
      match[1]
    else
      citation_year.to_i
    end
  end

  ###############################################
  def references options = {}
    references = []
    Taxt.taxt_fields.each do |klass, fields|
      klass.send(:all).each do |record|
        fields.each do |field|
          next unless record[field]
          if record[field] =~ /{ref #{id}}/
            references << { table: klass.table_name, id: record[:id], field: field }
            return true if options[:any?]
          end
        end
      end
    end

    # Previously looped over [Citation, Bolton::Match].each ...
    Citation.where(reference_id: id).all.each do |record|
      references << { table: Citation.table_name, id: record[:id], field: :reference_id }
      return true if options[:any?]
    end

    NestedReference.where(nesting_reference_id: id).all.each do |record|
      references << { table: 'references', id: record[:id], field: :nesting_reference_id }
      return true if options[:any?]
    end
    return false if options[:any?]
    references
  end

  def any_references?
    self.references any?: true
  end

  def self.approve_all
    Reference.where.not(review_state: "reviewed").find_each do |reference|
      reference.review_state = 'reviewed'
      reference.save!
    end
  end

  private
    def strip_text_fields
      [:title, :public_notes, :editor_notes, :taxonomic_notes, :citation].each do |field|
        value = self[field]
        next unless value.present?
        value.gsub! /(\n|\r|\n\r|\r\n)/, ' '
        value.strip!
        value.squeeze! ' '
        self[field] = value
      end
    end

    def set_year_from_citation_year
      self.year = self.class.citation_year_to_year citation_year
    end

    def set_author_names_caches(*)
      self.author_names_string_cache, self.principal_author_last_name_cache = make_author_names_caches
    end

    def make_author_names_caches
      string = author_names.map(&:name).join('; ')
      string << author_names_suffix if author_names_suffix.present?
      first_author_name = author_names.first
      last_name = first_author_name && first_author_name.last_name
      return string, last_name
    end

    class DuplicateMatcher < ReferenceMatcher
      def min_similarity
        0.5
      end
    end

end
