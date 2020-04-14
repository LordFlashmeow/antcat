# frozen_string_literal: true

# Use `rails generate database_script <name_of_script>` to generate new scripts.

class DatabaseScript
  include Draper::Decoratable
  include DatabaseScripts::Rendering
  include DatabaseScripts::ViewHelpers

  SCRIPTS_DIR = "app/database_scripts/database_scripts"

  ScriptNotFound = Class.new StandardError

  attr_accessor :results_runtime

  delegate :section, :category, :tags, :issue_description, :description, to: :end_data_attributes

  class << self
    def inherited subclass
      subclass.include Rails.application.routes.url_helpers
      subclass.include ActionView::Helpers::UrlHelper
    end

    def new_from_filename basename
      raise ScriptNotFound unless (script_class = "DatabaseScripts::#{basename.camelize}".safe_constantize)
      script_class.new
    end

    def safe_new_from_filename class_name
      new_from_filename(class_name)
    rescue DatabaseScript::ScriptNotFound
      DatabaseScripts::UnfoundDatabaseScript.new(class_name)
    end

    def all
      @_all ||= Dir.glob("#{SCRIPTS_DIR}/*").sort.map { |path| new_from_filename(File.basename(path, ".rb")) }
    end

    # TODO: Indicate record type in scripts.
    def record_in_results? record
      new.results.where(id: record.id).exists?
    end
  end

  def soft_validated?
    self.class.in?(SoftValidations::ALL_DATABASE_SCRIPTS_TO_CHECK)
  end

  def fix_random?
    self.class.in?(Catalog::FixRandomController::DATABASE_SCRIPTS_TO_CHECK)
  end

  def slow?
    tags.include?(DatabaseScripts::Tagging::SLOW_TAG) || tags.include?(DatabaseScripts::Tagging::VERY_SLOW_TAG)
  end

  def title
    end_data_attributes.title || filename_without_extension.humanize(keep_id_suffix: true)
  end

  def related_scripts
    end_data_attributes.related_scripts.reject { |database_script| database_script.is_a?(self.class) }
  end

  def statistics
    @_statistics ||= default_statistics
  end

  def filename_without_extension
    @_filename_without_extension ||= self.class.name.demodulize.underscore
  end

  # For `link_to "database_script", database_script_path(@database_script)`.
  def to_param
    filename_without_extension
  end

  protected

    def cached_results
      return @_results if defined? @_results
      if respond_to?(:results)
        start = Time.current
        @_results = results
        @_results = @_results.load if @_results.is_a?(ActiveRecord::Relation)
        self.results_runtime = Time.current - start
      end
      @_results
    end

  private

    def end_data_attributes
      @_end_data_attributes ||= DatabaseScripts::EndDataAttributes.new(script_path)
    end

    def script_path
      "#{SCRIPTS_DIR}/#{filename_without_extension}.rb"
    end

    def default_statistics
      return unless respond_to? :results
      count = cached_results.count
      count = count.count if count.is_a?(Hash) # HACK: For grouped queries.
      "Results: #{count}"
    end
end
