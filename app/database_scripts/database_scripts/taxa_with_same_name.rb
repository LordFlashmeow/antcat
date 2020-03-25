module DatabaseScripts
  class TaxaWithSameName < DatabaseScript
    def results
      same_name = Taxon.joins(:name).group('names.name').having('COUNT(*) > 1')

      Taxon.joins(:name).where(names: { name: same_name.select(:name) }).
        order('names.name').
        includes(protonym: { authorship: { reference: :author_names } }).references(:reference_author_names)
    end

    def render
      as_table do |t|
        t.header 'Taxon', 'Authorship', 'Status'
        t.rows do |taxon|
          [
            markdown_taxon_link(taxon),
            taxon.authorship_reference.keey,
            taxon.status
          ]
        end
      end
    end
  end
end

__END__

category: Catalog
tags: [list]

related_scripts:
  - SameNamedPassThroughNames
  - TaxaWithSameName
  - TaxaWithSameNameAndStatus
  - ProtonymsWithSameName
  - ProtonymsWithSameNameExcludingSubgenusPart