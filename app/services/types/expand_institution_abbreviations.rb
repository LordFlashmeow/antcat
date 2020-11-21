# frozen_string_literal: true

module Types
  class ExpandInstitutionAbbreviations
    include Service

    STOP_REGEX = %r{
      (?!               # Negative look-ahead.
        (?:             # Non-capturing.
          [^$\]), .;:/] # Only match abbreviations followed by any of these characters.
        )
      )
    }x

    def initialize content
      @content = content.dup
    end

    def call
      return content if institutions_regex.blank?
      expand_institution_abbreviations!
    end

    private

      attr_reader :content

      def expand_institution_abbreviations!
        content.gsub!(/\b(#{institutions_regex})#{STOP_REGEX}/) do |abbr|
          name = Institution.find_by(abbreviation: abbr).name
          "<abbr title='#{CGI.escapeHTML(name)}'>#{abbr}</abbr>"
        end

        content
      end

      # TODO: Improve performance, since there are now way more
      # institutions in the db than when this was written.
      def institutions_regex
        @_institutions_regex ||= Institution.pluck(:abbreviation).join('|')
      end
  end
end
