module DatabaseScripts
  class SynonymsWithoutACurrentValidTaxon < DatabaseScript
    def results
      Taxon.where(status: 'synonym').where(current_valid_taxon: nil)
    end
  end
end

__END__
description: >
  Note that the taxon header may still say
  "junior synonym of current valid taxon *Taxon name*" if *Taxon name*
  is a senior synonym of the taxon.
topic_areas: [synonyms]
