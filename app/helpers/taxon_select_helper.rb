# frozen_string_literal: true

module TaxonSelectHelper
  def taxon_select_tag taxon_attribute_name, taxon_id, rank: nil
    taxon = Taxon.find_by(id: taxon_id)
    taxon_id = taxon&.id

    select_tag taxon_attribute_name,
      options_for_select([taxon_id].compact, taxon_id),
      class: 'select2-autocomplete', data: taxon_data_attributes(taxon, rank)
  end

  private

    def taxon_data_attributes taxon, rank
      for_taxon = if taxon
                    {
                      name_html: taxon.name.name_html,
                      name_with_fossil: taxon.name_with_fossil,
                      author_citation: taxon.author_citation,
                      css_classes: CatalogFormatter.taxon_disco_mode_css(taxon)
                    }
                  end

      { taxon_select: true, rank: rank }.merge(for_taxon || {})
    end

    module FormBuilderAdditions
      include ActionView::Helpers::FormOptionsHelper
      include TaxonSelectHelper

      def taxon_select taxon_attribute_name, rank: nil
        taxon = object.public_send taxon_attribute_name
        taxon_id = taxon&.id

        select "#{taxon_attribute_name}_id".to_sym,
          options_for_select([taxon_id].compact, taxon_id),
          { include_blank: '(none)' },
          class: 'select2-autocomplete', data: taxon_data_attributes(taxon, rank)
      end
    end
end

ActionView::Helpers::FormBuilder.include TaxonSelectHelper::FormBuilderAdditions
