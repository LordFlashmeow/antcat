# frozen_string_literal: true

module DatabaseScripts
  class ProtonymsWithTaxaWithVeryDifferentEpithets < DatabaseScript
    FALSE_POSITIVES = [
      "ager agra",
      "indificans nidificans",
      "rubiginosa ruiginosa",
      "siloicola sylvicola",
      "tailori taylori"
    ]

    def results
      Protonym.joins(taxa: :name).
        where(taxa: { type: Rank::SPECIES_GROUP_NAMES }).
        where.not(taxa: { status: Status::UNAVAILABLE_MISSPELLING }).
        group('protonyms.id').having("COUNT(DISTINCT SUBSTR(names.epithet, 1, 3)) > 1").distinct.
        includes(:name)
    end

    def render
      as_table do |t|
        t.header 'Protonym', 'Epithets of taxa', 'Ranks of taxa', 'Statuses of taxa', 'Taxa',
          'Looks like a false positive?'

        t.rows do |protonym|
          epithets = protonym.taxa.joins(:name).distinct.pluck(:epithet)
          false_positive = epithets.sort.join(' ').in?(FALSE_POSITIVES)

          [
            protonym.decorate.link_to_protonym,
            epithets.join(', '),
            protonym.taxa.pluck(:type).join(', '),
            protonym.taxa.pluck(:status).join(', '),
            taxon_links(protonym.taxa),
            (false_positive ? 'Yes' : bold_warning('No'))
          ]
        end
      end
    end
  end
end

__END__

section: regression-test
category: Protonyms
tags: []

issue_description: The taxa of this protonym have very different epithets.

description: >
  "Very different" means that the first three letters in the epithet are not the same.


  Only species checked.

related_scripts:
  - ProtonymsWithTaxaWithVeryDifferentEpithets
  - ObsoleteCombinationsWithVeryDifferentEpithets
