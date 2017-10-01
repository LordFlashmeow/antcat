# This class is for parsing taxts in the "database format" (strings
# such as "hey {ref 123}") to something that can be read.

class TaxtPresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper

  def initialize taxt_from_db
    @taxt = taxt_from_db.try :dup
  end
  class << self; alias_method :[], :new end

  # Parses "example {tax 429361}"
  # into   "example <a href=\"/catalog/429361\">Melophorini</a>"
  def to_html
    parse :to_html
  end

  # Parses "example {tax 429361}"
  # into   "example Melophorini"
  def to_text
    parse :to_text
  end

  def to_antweb
    parse :to_antweb
  end

  private
    def parse format
      return '' unless @taxt.present?

      @format = format

      parse_refs!
      parse_nams!
      parse_taxs!

      @taxt.html_safe
    end

    # References, "{ref 123}".
    def parse_refs!
      @taxt.gsub!(/{ref (\d+)}/) do
        reference = Reference.find_by id: $1

        if reference
          case @format
          when :to_html   then reference.decorate.inline_citation
          when :to_text   then reference.keey
          when :to_antweb then Exporters::Antweb::InlineCitation[reference]
          end
        else
          warn_about_non_existing_id "REFERENCE", $1
        end
      end
    end

    # Names, "{nam 123}".
    def parse_nams!
      @taxt.gsub!(/{nam (\d+)}/) do
        name = Name.find_by id: $1

        if name
          name.to_html
        else
          warn_about_non_existing_id "NAME", $1
        end
      end
    end

    # Taxa, "{tax 123}".
    def parse_taxs!
      @taxt.gsub!(/{tax (\d+)}/) do
        taxon = Taxon.find_by id: $1

        if taxon
          case @format
          when :to_html   then taxon.decorate.link_to_taxon
          when :to_text   then taxon.name.to_html
          when :to_antweb then Exporters::Antweb::Exporter.antcat_taxon_link_with_name taxon
          end
        else
          warn_about_non_existing_id "TAXON", $1
        end
      end
    end

    def warn_about_non_existing_id klass, id
      <<-HTML.squish
        <span class="bold-warning">
          CANNOT FIND #{klass} WITH ID #{id}#{seach_history_link(id)}
        </span>
      HTML
    end

    def seach_history_link id
      case @format
      when :to_html
        " " + link_to("Search history?", versions_path(item_id: id),
          class: "btn-normal btn-tiny")
      when :to_text
        "" # Probably do not show when `:to_text`...
      when :to_antweb
        "" # Don't show when exporting to AntWeb.
      end
    end
end