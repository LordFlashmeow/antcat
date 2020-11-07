# frozen_string_literal: true

class ProtonymDecorator < Draper::Decorator
  delegate :locality, :uncertain_locality?, :forms, :authorship

  def link_to_protonym
    link_to_protonym_with_label name_with_fossil
  end

  def link_to_protonym_with_author_citation
    link_to_protonym << ' ' << protonym.author_citation.html_safe
  end

  def link_to_protonym_epithet
    link_to_protonym_with_label(protonym.name.epithet_html)
  end

  def link_to_protonym_with_linked_author_citation
    link_to_protonym <<
      ' ' <<
      h.tag.span(
        h.link_to(protonym.author_citation.html_safe, h.reference_path(protonym.authorship_reference)),
        class: 'discret-author-citation'
      )
  end

  def name_with_fossil
    protonym.name.name_with_fossil_html protonym.fossil?
  end

  def format_nomen_attributes
    return @_format_nomen_attributes if defined?(@_format_nomen_attributes)

    @_format_nomen_attributes ||= begin
      nomen_attributes.join.html_safe if nomen_attributes.present?
    end
  end

  def format_locality
    return unless locality

    first_parenthesis = locality.index("(")
    capitalized =
      if first_parenthesis
        before = locality[0...first_parenthesis]
        rest = locality[first_parenthesis..]
        before.mb_chars.upcase + rest
      else
        locality.mb_chars.upcase
      end

    capitalized += ' [uncertain]' if uncertain_locality?
    h.add_period_if_necessary capitalized
  end

  def format_pages_and_forms
    string = authorship.pages.dup
    string << " (#{forms})" if forms
    string
  end

  private

    def link_to_protonym_with_label label
      h.link_to label, h.protonym_path(protonym), class: 'protonym protonym-hover-preview-link'
    end

    def nomen_attributes
      @_nomen_attributes ||= [
        ('<i>Nomen nudum</i>' if protonym.nomen_nudum?),
        ('<i>Nomen novum</i>' if protonym.nomen_novum?),
        ('<i>Nomen oblitum</i>' if protonym.nomen_oblitum?),
        ('<i>Nomen dubium</i>' if protonym.nomen_dubium?),
        ('<i>Nomen conservandum</i>' if protonym.nomen_conservandum?),
        ('<i>Nomen protectum</i>' if protonym.nomen_protectum?)
      ].compact
    end
end
