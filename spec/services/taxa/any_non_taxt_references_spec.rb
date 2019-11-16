require 'rails_helper'

describe Taxa::AnyNonTaxtReferences do
  describe "#call" do
    let!(:taxon) { create :family }

    context "when taxon has non-taxt references" do
      before do
        create :family, :homonym, homonym_replaced_by: taxon
      end

      specify { expect(described_class[taxon]).to eq true }
    end

    context "when taxon has no non-taxt references" do
      before do
        create :family, type_taxt: "{tax #{taxon.id}}"
      end

      specify { expect(described_class[taxon]).to eq false }
    end
  end
end
