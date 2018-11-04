require 'spec_helper'

describe Taxa::NameForNewCombination do
  describe "#call" do
    let(:species) { create_species "Lasius cactusia" }

    context "when `new_comb_parent` is a species" do
      let(:new_comb_parent) { species }
      let(:old_comb) { create_subspecies "Formica luigi peligrosa" }

      it "returns a correctly formatted `SubspeciesName`" do
        new_comb_name = described_class[old_comb, new_comb_parent]

        expect(new_comb_name).to be_a SubspeciesName
        expect(new_comb_name.name).to eq "Lasius cactusia peligrosa"
      end
    end

    context "when `new_comb_parent` is a genus" do
      let(:new_comb_parent) { create_genus "Atta" }
      let(:old_comb) { species }

      it "returns a correctly formatted `SpeciesName`" do
        new_comb_name = described_class[old_comb, new_comb_parent]

        expect(new_comb_name).to be_a SpeciesName
        expect(new_comb_name.name).to eq "Atta cactusia"
      end
    end

    context "when invalid rank combinations" do
      let(:new_comb_parent) { create(:subfamily) } # uncombinable_parent
      let(:old_comb) { species }

      specify do
        expect { described_class[old_comb, new_comb_parent] }.
          to raise_error /uncombinable/
      end
    end
  end
end