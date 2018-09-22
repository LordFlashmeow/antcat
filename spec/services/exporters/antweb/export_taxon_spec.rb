require 'spec_helper'

describe Exporters::Antweb::ExportTaxon do
  subject(:exporter) { described_class.new }

  def export_taxon taxon
    exporter.call(taxon)
  end

  describe "HEADER" do
    it "is the same as the code" do
      expected = "antcat id\t" +
        "subfamily\t" +
        "tribe\t" +
        "genus\t" +
        "subgenus\t" +
        "species\t" +
        "subspecies\t" +
        "author date\t" +
        "author date html\t" +
        "authors\t" +
        "year\t" +
        "status\t" +
        "available\t" +
        "current valid name\t" +
        "original combination\t" +
        "was original combination\t" +
        "fossil\t" +
        "taxonomic history html\t" +
        "reference id\t" +
        "bioregion\t" +
        "country\t" +
        "current valid rank\t" +
        "hol id\t" +
        "current valid parent"
      expect(described_class::HEADER).to eq expected
    end
  end

  describe "#call" do
    let(:ponerinae) { create_subfamily 'Ponerinae' }
    let(:attini) { create_tribe 'Attini', subfamily: ponerinae }
    let(:taxon) { create :family }

    describe "[0]: `antcat_id`" do
      specify { expect(export_taxon(taxon)[0]).to eq taxon.id }
    end

    describe "[8]: `author date html`" do
      specify do
        reference = taxon.authorship_reference
        expect(export_taxon(taxon)[8]).
          to eq %(<span title="#{reference.decorate.plain_text}">#{reference.keey}</span>)
      end
    end

    describe "[11]: `status`" do
      specify { expect(export_taxon(taxon)[11]).to eq taxon.status }
    end

    describe "[12]: `available`" do
      context "when taxon is valid" do
        specify { expect(export_taxon(taxon)[12]).to eq 'TRUE' }
      end

      context "when taxon is not valid" do
        let(:taxon) { create :family, :synonym }

        specify { expect(export_taxon(taxon)[12]).to eq 'FALSE' }
      end
    end

    describe "[13]: `current valid name`" do
      let(:taxon) { create :genus }

      context 'when taxon is valid' do
        it "returns nil" do
          expect(export_taxon(taxon)[13]).to be_nil
        end
      end

      context "when taxon has a `current_valid_taxon`" do
        let!(:old) { create :genus }

        before { taxon.update! current_valid_taxon: old, status: Status::SYNONYM }

        it "exports the current valid name of the taxon" do
          expect(export_taxon(taxon)[13]).to end_with old.name.name
        end
      end

      context "when there isn't a current_valid_taxon" do
        let!(:junior_synonym) { create :species, :synonym, genus: taxon }

        before do
          senior_synonym = create_species 'Eciton major', genus: taxon
          create :synonym, junior_synonym: junior_synonym, senior_synonym: senior_synonym
        end

        it "looks at synonyms" do
          expect(export_taxon(junior_synonym)[13]).to end_with 'Eciton major'
        end
      end
    end

    # So that AntWeb knows when to use parentheses around authorship.
    # NOTE: This and `was original combination` have been mixed up, but it's been like that forever.
    describe "[14]: `original combination`" do
      specify do
        taxon = create :genus, :original_combination
        expect(export_taxon(taxon)[14]).to eq 'TRUE'
      end

      specify do
        taxon = create :genus
        expect(export_taxon(taxon)[14]).to eq 'FALSE'
      end
    end

    # NOTE: See above.
    describe "[15]: `was original combination`" do
      context "when there was no recombining" do
        specify { expect(export_taxon(taxon)[15]).to eq nil }
      end

      context "when there has been some recombining" do
        let(:recombination) { create :species }
        let(:original_combination) { create :species, :original_combination, current_valid_taxon: recombination }

        before do
          recombination.protonym.name = original_combination.name
          recombination.save!
        end

        it "is the protonym" do
          expect(export_taxon(recombination)[15]).to eq original_combination.name.name
        end
      end
    end

    describe "[16]: `fossil`" do
      context "when taxon is not fossil" do
        specify { expect(export_taxon(taxon)[16]).to eq 'FALSE' }
      end

      context "when taxon is fossil" do
        let(:taxon) { create :family, fossil: true }

        specify { expect(export_taxon(taxon)[16]).to eq 'TRUE' }
      end
    end

    describe "[17]: `taxonomic history html`" do
      context "a genus" do
        let!(:shared_name) { create :genus_name, name: 'Atta' }
        let!(:protonym) do
          author_name = create :author_name, name: 'Bolton, B.'
          reference = ArticleReference.new author_names: [author_name],
            title: 'Ants I have known',
            citation_year: '2010a',
            journal: create(:journal, name: 'Psyche'),
            series_volume_issue: '1',
            pagination: '2'
          authorship = create :citation, reference: reference, pages: '12'
          create :protonym, name: shared_name, authorship: authorship
        end

        let!(:genus) { create :genus, name: shared_name, protonym: protonym, hol_id: 9999 }
        let!(:species) { create_species 'Atta major', genus: genus }

        it "formats a taxon's history for AntWeb" do
          authorship_reference_id = genus.authorship_reference.id

          genus.update type_name: species.name
          genus.history_items.create taxt: "Taxon: {tax #{species.id}} Name: {nam #{species.name.id}}"

          a_reference = create :article_reference, doi: "10.10.1038/nphys1170"
          a_tribe = create :tribe
          genus.reference_sections.create title_taxt: "Subfamily and tribe {tax #{a_tribe.id}}",
            references_taxt: "{ref #{a_reference.id}}: 766 (diagnosis);"
          ref_author = a_reference.authors_for_keey
          ref_year = a_reference.citation_year
          ref_title = a_reference.title
          ref_journal_name = a_reference.journal.name
          ref_pagination = a_reference.pagination
          ref_volume = a_reference.series_volume_issue
          ref_doi = a_reference.doi

          expect(export_taxon(genus)[17]).to eq(
            %(<div class="antcat_taxon">) +

              # statistics
              %(<div class="statistics">) +
                %(<p>1 species</p>) +
              %(</div>) +

              # headline
              %(<div>) +
                # protonym
                %(<b><span><i>Atta</i></span></b> ) +

                # authorship
                %(<span>) +
                  %(<a title="Bolton, B. 2010a. Ants I have known. Psyche 1:2." href="http://antcat.org/references/#{authorship_reference_id}">Bolton, 2010a</a>) +
                  %(: 12) +
                %(</span>) +
                %(. ) +

                # type
                %(<span>Type-species: <a class="link_to_external_site" href="http://www.antcat.org/catalog/#{species.id}"><i>Atta major</i></a>.</span>) +
                %( ) +
                # links
                %(<a class="link_to_external_site" href="http://www.antcat.org/catalog/#{genus.id}">AntCat</a>) +
                %( ) +
                %(<a class="link_to_external_site" href="http://www.antwiki.org/wiki/Atta">AntWiki</a>) +
                %( ) +
                %(<a class="link_to_external_site" href="http://hol.osu.edu/index.html?id=9999">HOL</a>) +

              %(</div>) +

              # taxonomic history
              %(<p><b>Taxonomic history</b></p>) +
              %(<div><div>) +
                %(<table><tr><td>) +
                  %(Taxon: <a class="link_to_external_site" href="http://www.antcat.org/catalog/#{species.id}"><i>Atta major</i></a> Name: <i>Atta major</i>.) +
                %(</td></tr></table>) +
              %(</div></div>) +

              # references
              %(<div>) +
                %(<div>) +
                  %(<div>Subfamily and tribe ) +
                    %(<a class="link_to_external_site" href="http://www.antcat.org/catalog/#{a_tribe.id}">) +
                      %(#{a_tribe.name_cache}) +
                    %(</a>) +
                  %(</div>) +
                  %(<div>) +
                    %(<a title="#{ref_author}, B.L. #{ref_year}. #{ref_title}. #{ref_journal_name} #{ref_volume}:#{ref_pagination}." href="http://antcat.org/references/#{a_reference.id}">) +
                      %(#{ref_author}, #{ref_year}) +
                    %(</a> ) +
                    %(<a href="http://dx.doi.org/#{ref_doi}">#{ref_doi}</a>) +
                    %{: 766 (diagnosis);} +
                  %(</div>) +
                %(</div>) +
              %(</div>) +

            %(</div>)
          )
        end
      end
    end

    describe "[18]: `reference id`" do
      let!(:taxon) { create :genus }

      it "sends the protonym's reference ID" do
        reference_id = export_taxon(taxon)[18]
        expect(reference_id).to eq taxon.authorship_reference.id
      end

      it "sends nil if the protonym's reference is a MissingReference" do
        taxon.protonym.authorship.reference = create :missing_reference
        taxon.save!
        reference_id = export_taxon(taxon)[18]
        expect(reference_id).to be_nil
      end
    end

    describe "[19]: `bioregion`" do
      it "sends the biogeographic region" do
        taxon = create :genus, biogeographic_region: 'Neotropic'
        expect(export_taxon(taxon)[19]).to eq 'Neotropic'
      end
    end

    describe "[20]: `country`" do
      it "sends the locality" do
        taxon = create :genus, protonym: create(:protonym, locality: 'Canada')
        expect(export_taxon(taxon)[20]).to eq 'Canada'
      end
    end

    describe "[21]: `current valid rank`" do
      it "sends the right value for each class" do
        expect(export_taxon(create(:subfamily))[21]).to eq 'Subfamily'
        expect(export_taxon(create(:genus))[21]).to eq 'Genus'
        expect(export_taxon(create(:subgenus))[21]).to eq 'Subgenus'
        expect(export_taxon(create(:species))[21]).to eq 'Species'
        expect(export_taxon(create(:subspecies))[21]).to eq 'Subspecies'
      end
    end

    describe "[23]: `current valid parent`" do
      let(:subfamily) { create_subfamily 'Dolichoderinae' }
      let(:tribe) { create_tribe 'Attini', subfamily: subfamily }
      let(:genus) { create_genus 'Atta', tribe: tribe, subfamily: subfamily }
      let(:subgenus) { create :subgenus, genus: genus, tribe: tribe, subfamily: subfamily }
      let(:species) { create_species 'Atta betta', genus: genus, subfamily: subfamily }

      it "doesn't punt on a subfamily's family" do
        taxon = create :subfamily
        expect(export_taxon(taxon)[23]).to eq 'Formicidae'
      end

      it "handles a taxon's subfamily" do
        taxon = create :tribe, subfamily: subfamily
        expect(export_taxon(taxon)[23]).to eq 'Dolichoderinae'
      end

      it "doesn't skip over tribe and return the subfamily" do
        taxon = create :genus, tribe: tribe
        expect(export_taxon(taxon)[23]).to eq 'Attini'
      end

      it "returns the subfamily only if there's no tribe" do
        taxon = create :genus, subfamily: subfamily, tribe: nil
        expect(export_taxon(taxon)[23]).to eq 'Dolichoderinae'
      end

      it "skips over subgenus and return the genus", :pending do
        skip "broke a long time ago"

        taxon = create :species, genus: genus, subgenus: subgenus
        expect(export_taxon(taxon)[23]).to eq 'Atta'
      end

      it "handles a taxon's species" do
        taxon = create :subspecies, species: species, genus: genus, subfamily: subfamily
        expect(export_taxon(taxon)[23]).to eq 'Atta betta'
      end

      it "handles a synonym" do
        senior = create_genus 'Eciton', subfamily: subfamily
        junior = create :genus, :synonym, subfamily: subfamily, current_valid_taxon: senior
        taxon = create :species, genus: junior
        create :synonym, senior_synonym: senior, junior_synonym: junior

        expect(export_taxon(taxon)[23]).to eq 'Eciton'
      end

      it "handles a genus without a subfamily" do
        taxon = create :genus, tribe: nil, subfamily: nil
        expect(export_taxon(taxon)[23]).to eq 'Formicidae'
      end

      it "handles a subspecies without a species" do
        taxon = create :subspecies, genus: genus, species: nil, subfamily: nil
        expect(export_taxon(taxon)[23]).to eq 'Atta'
      end
    end

    it "can export a subfamily" do
      create_genus subfamily: ponerinae, tribe: nil
      expect(export_taxon(ponerinae)[1..6]).to eq [
        'Ponerinae', nil, nil, nil, nil, nil
      ]
    end

    it "can export a genus" do
      dacetini = create_tribe 'Dacetini', subfamily: ponerinae
      acanthognathus = create_genus 'Acanothognathus', subfamily: ponerinae, tribe: dacetini

      expect(export_taxon(acanthognathus)[1..6]).to eq [
        'Ponerinae', 'Dacetini', 'Acanothognathus', nil, nil, nil
      ]
    end

    it "can export a genus without a tribe" do
      acanthognathus = create_genus 'Acanothognathus', subfamily: ponerinae, tribe: nil
      expect(export_taxon(acanthognathus)[1..6]).to eq [
        'Ponerinae', nil, 'Acanothognathus', nil, nil, nil
      ]
    end

    it "can export a genus without a subfamily as being in 'incertae_sedis'" do
      acanthognathus = create_genus 'Acanothognathus', tribe: nil, subfamily: nil
      expect(export_taxon(acanthognathus)[1..6]).to eq [
        'incertae_sedis', nil, 'Acanothognathus', nil, nil, nil
      ]
    end

    describe "Exporting species" do
      it "exports one correctly" do
        atta = create_genus 'Atta', tribe: attini
        species = create_species 'Atta robustus', genus: atta

        expect(export_taxon(species)[1..6]).to eq [
          'Ponerinae', 'Attini', 'Atta', nil, 'robustus', nil
        ]
      end

      it "can export a species without a tribe" do
        atta = create_genus 'Atta', subfamily: ponerinae, tribe: nil
        species = create_species 'Atta robustus', genus: atta

        expect(export_taxon(species)[1..6]).to eq [
          'Ponerinae', nil, 'Atta', nil, 'robustus', nil
        ]
      end

      it "exports a species without a subfamily as being in the 'incertae sedis' subfamily" do
        atta = create_genus 'Atta', subfamily: nil, tribe: nil
        species = create_species 'Atta robustus', genus: atta

        expect(export_taxon(species)[1..6]).to eq [
          'incertae_sedis', nil, 'Atta', nil, 'robustus', nil
        ]
      end
    end

    describe "Exporting subspecies" do
      it "exports one correctly" do
        atta = create_genus 'Atta', subfamily: ponerinae, tribe: attini
        species = create_species 'Atta robustus', subfamily: ponerinae, genus: atta
        subspecies = create_subspecies 'Atta robustus emeryii', subfamily: ponerinae, genus: atta, species: species

        expect(export_taxon(subspecies)[1..6]).to eq [
          'Ponerinae', 'Attini', 'Atta', nil, 'robustus', 'emeryii'
        ]
      end

      it "can export a subspecies without a tribe" do
        atta = create_genus 'Atta', subfamily: ponerinae, tribe: nil
        species = create_species 'Atta robustus', subfamily: ponerinae, genus: atta
        subspecies = create_subspecies 'Atta robustus emeryii', genus: atta, species: species

        expect(export_taxon(subspecies)[1..6]).to eq [
          'Ponerinae', nil, 'Atta', nil, 'robustus', 'emeryii'
        ]
      end

      it "exports a subspecies without a subfamily as being in the 'incertae sedis' subfamily" do
        atta = create_genus 'Atta', subfamily: nil, tribe: nil
        species = create_species 'Atta robustus', subfamily: nil, genus: atta
        subspecies = create_subspecies 'Atta robustus emeryii', subfamily: nil, genus: atta, species: species

        expect(export_taxon(subspecies)[1..6]).to eq [
          'incertae_sedis', nil, 'Atta', nil, 'robustus', 'emeryii'
        ]
      end
    end
  end

  describe "Sending all taxa - not just valid" do
    it "can export a junior synonym" do
      taxon = create :genus, :original_combination
      expect(export_taxon(taxon)[11]).to eq 'original combination'
    end

    it "can export a Tribe" do
      taxon = create :tribe
      expect(export_taxon(taxon)).not_to be_nil
    end

    it "can export a Subgenus" do
      taxon = create_subgenus 'Atta (Boyo)'
      expect(export_taxon(taxon)[4]).to eq 'Boyo'
    end
  end
end
