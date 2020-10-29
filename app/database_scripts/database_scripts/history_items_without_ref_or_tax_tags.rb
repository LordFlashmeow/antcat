# frozen_string_literal: true

module DatabaseScripts
  class HistoryItemsWithoutRefOrTaxTags < DatabaseScript
    def results
      HistoryItem.where(Taxt::HistoryItemCleanup::NO_REF_OR_TAX_OR_PRO_TAG).
        includes(protonym: :name)
    end

    def render
      as_table do |t|
        t.header 'History item', 'Taxon', 'Status', 'taxt',
          'Looks like protonym data?', 'Simple known format?', 'Protonym'
        t.rows do |history_item|
          taxt = history_item.taxt
          taxon = history_item.terminal_taxon
          protonym = history_item.protonym
          looks_like_it_belongs_to_the_protonym = looks_like_it_belongs_to_the_protonym?(taxt)
          simple_known_format = simple_known_format?(taxt)

          [
            link_to(history_item.id, history_item_path(history_item)),
            taxon_link(taxon),
            taxon.status,
            Detax[taxt],
            ('Yes' if looks_like_it_belongs_to_the_protonym),
            ('Yes' if simple_known_format),
            protonym.decorate.link_to_protonym
          ]
        end
      end
    end

    def simple_known_format? taxt
      taxt.in?(['Unavailable name', '<i>Nomen nudum</i>'])
    end

    def looks_like_it_belongs_to_the_protonym? taxt
      taxt.starts_with?(',') ||
        taxt =~ /[A-Z]{5,}/
    end
  end
end

__END__

title: History items without <code>ref</code> or <code>tax</code> tags

section: research
category: Taxt
tags: []

description: >
  "Looks like protonym data" = item starts with a comma, or contains five or more uppercase letters
