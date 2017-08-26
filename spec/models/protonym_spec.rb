require 'spec_helper'

describe Protonym do
  it { should be_versioned }
  it { should validate_presence_of :authorship }

  describe "#destroy" do
    describe "Cascading delete" do
      let!(:protonym) { create :protonym }

      it "deletes the citation when the protonym is deleted" do
        expect(described_class.count).to eq 1
        expect(Citation.count).to eq 1

        protonym.destroy

        expect(described_class.count).to be_zero
        expect(Citation.count).to be_zero
      end
    end
  end
end
