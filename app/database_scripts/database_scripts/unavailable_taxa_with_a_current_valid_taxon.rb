module DatabaseScripts
  class UnavailableTaxaWithACurrentValidTaxon < DatabaseScript
    def results
      Taxon.where(status: "unavailable").where.not(current_valid_taxon: nil)
    end
  end
end

__END__
tags: [regression-test]
topic_areas: [catalog]