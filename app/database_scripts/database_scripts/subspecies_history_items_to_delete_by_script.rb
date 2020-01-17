module DatabaseScripts
  class SubspeciesHistoryItemsToDeleteByScript < DatabaseScript
    def results
      subspecies_history_items = TaxonHistoryItem.where('taxt LIKE ?', "%Current subspecies%").
        joins(:taxon).joins("INNER JOIN taxa subspecies_taxa ON subspecies_taxa.species_id = taxa.id").
        where("taxa.status = 'valid' AND subspecies_taxa.status = 'valid'").distinct

      subspecies_history_items.to_a.select do |history_item|
        Taxa::SubspeciesHistoryItemIssues[history_item].blank?
      end
    end

    def render
      as_table do |t|
        t.header :history_item, :species, :rank, :status
        t.rows do |history_item|
          taxon = history_item.taxon

          [
            link_to(history_item.id, taxon_history_item_path(history_item)),
            markdown_taxon_link(taxon),
            taxon.rank,
            taxon.status
          ]
        end
      end
    end
  end
end

__END__

category: Script (pending)
tags: [new!, slow]

description: >
  See %github838

related_scripts:
  - SubspeciesHistoryItemsToDeleteByScript
  - SubspeciesListInHistoryItem
  - SubspeciesListInHistoryItemVsSubspeciesFromDatabase
