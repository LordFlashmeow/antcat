require 'spec_helper'

describe Taxa::CreateObsoleteCombination do
  describe "#call" do
    describe "unsuccessful case" do
      context "when a species with this name already exists" do
        let!(:current_valid_taxon) { create_species 'Strumigenys ravidura' }
        let!(:obsolete_genus) { create_genus 'Pyramica' }

        before do
          create_genus 'Pyramica ravidura'
        end

        it "does not create a new taxon" do
          expect { described_class[current_valid_taxon, obsolete_genus] }.to_not change { Taxon.count }
        end

        it "returns the new non-persisted subspecies with errors" do
          obsolete_combination = described_class[current_valid_taxon, obsolete_genus]
          expect(obsolete_combination.errors[:base]).to eq ["This name is in use by another taxon"]
        end
      end
    end

    describe "successful case" do
      context "when there is no name collision" do
        let!(:current_valid_taxon) { create :species }
        let!(:obsolete_genus) { create :genus }

        it "does not modify the original species record" do
          expect { described_class[current_valid_taxon, obsolete_genus] }.to_not change { current_valid_taxon.reload.attributes }
        end

        it "creates a new taxon" do
          expect { described_class[current_valid_taxon, obsolete_genus] }.to change { Taxon.count }.by(1)
        end

        it "returns the new species" do
          expect(described_class[current_valid_taxon, obsolete_genus]).to be_a Species
        end

        it "creates a new species name with the correct name parts" do
          obsolete_combination = described_class[current_valid_taxon, obsolete_genus]

          expect(obsolete_combination.name).to be_a SpeciesName

          current_valid_taxon_species_epithet = current_valid_taxon.name.epithet
          new_name = "#{obsolete_genus.name.name} #{current_valid_taxon_species_epithet}"

          expect(obsolete_combination.name.name).to eq new_name
          expect(obsolete_combination.name.name_html).to eq "<i>#{new_name}</i>"
          expect(obsolete_combination.name.name_to_html).to eq "<i>#{new_name}</i>"
          expect(obsolete_combination.name.epithet).to eq current_valid_taxon_species_epithet
          expect(obsolete_combination.name.epithet_html).to eq "<i>#{current_valid_taxon_species_epithet}</i>"
        end

        it "sets the status to obsolete combination" do
          obsolete_combination = described_class[current_valid_taxon, obsolete_genus]
          expect(obsolete_combination.status).to eq Status::OBSOLETE_COMBINATION
        end

        it "sets the current valid taxon to the current valid taxon" do
          obsolete_combination = described_class[current_valid_taxon, obsolete_genus]
          expect(obsolete_combination.current_valid_taxon).to eq current_valid_taxon
        end

        it "sets the protonym to the current valid taxon's protonym" do
          obsolete_combination = described_class[current_valid_taxon, obsolete_genus]
          expect(obsolete_combination.protonym).to eq current_valid_taxon.protonym
        end

        it "sets the parent genus to the obsolete genus" do
          obsolete_combination = described_class[current_valid_taxon, obsolete_genus]
          expect(obsolete_combination.genus).to eq obsolete_genus
        end
      end
    end
  end
end
