# frozen_string_literal: true

module Exporters
  module Antweb
    module History
      class Headline
        class HeadlineProtonym
          include ActionView::Context # For `#content_tag`.`
          include ActionView::Helpers::TagHelper # For `#content_tag`.`
          include Service

          attr_private_initialize :protonym

          def call
            AddPeriodIfNecessary[headline_protonym]
          end

          private

            def headline_protonym
              [
                protonym_name,
                authorship(protonym.authorship),
                ('[sic]' if protonym.sic?),
                protonym.decorate.format_locality
              ].compact.join(" ").html_safe
            end

            def protonym_name
              content_tag :b, protonym.decorate.name_with_fossil
            end

            def authorship authorship
              string = AntwebFormatter.link_to_reference(authorship.reference)
              string << ": "
              string << protonym.decorate.format_pages_and_forms

              if authorship.notes_taxt
                string << ' ' << AntwebFormatter.detax(authorship.notes_taxt)
              end

              string
            end
        end
      end
    end
  end
end