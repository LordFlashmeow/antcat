require 'spec_helper'

describe Taxa::Statistics::FormatStatistics do
  describe '#call' do
    context 'when statistics is blank' do
      specify do
        expect(described_class[nil]).to eq nil
        expect(described_class[{}]).to eq nil
      end
    end

    context "when there is both extant and fossil statistics" do
      let(:statistics) do
        {
          extant: {
            subfamilies: { 'valid' => 1 },
            genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
            species: { 'valid' => 1 }
          },
          fossil: {
            subfamilies: { 'valid' => 2 }
          }
        }
      end

      specify do
        expect(described_class[statistics]).
          to eq '<p>Extant: 1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>' \
          '<p>Fossil: 2 valid subfamilies</p>'
      end
    end

    context "when there fossil statistics only" do
      let(:statistics) do
        {
          fossil: { subfamilies: { 'valid' => 2 } }
        }
      end

      specify do
        expect(described_class[statistics]).to eq '<p>Fossil: 2 valid subfamilies</p>'
      end
    end

    it "formats the family's statistics correctly" do
      statistics = {
        extant: {
          subfamilies: { 'valid' => 1 },
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        }
      }
      expect(described_class[statistics]).
        to eq '<p>Extant: 1 valid subfamily, 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>'
    end

    it "handles tribes" do
      statistics = {
        extant: { tribes: { 'valid' => 1 } }
      }
      expect(described_class[statistics]).to eq '<p>Extant: 1 valid tribe</p>'
    end

    it "formats a subfamily's statistics correctly" do
      statistics = {
        extant: {
          genera: { 'valid' => 2, 'synonym' => 1, 'homonym' => 2 },
          species: { 'valid' => 1 }
        }
      }
      expect(described_class[statistics]).
        to eq '<p>Extant: 2 valid genera (1 synonym, 2 homonyms), 1 valid species</p>'
    end

    it "uses the singular for genus" do
      statistics = {
        extant: { genera: { 'valid' => 1 } }
      }
      expect(described_class[statistics]).to eq '<p>Extant: 1 valid genus</p>'
    end

    it "formats a genus's statistics correctly" do
      statistics = {
        extant: { species: { 'valid' => 1 } }
      }
      expect(described_class[statistics]).to eq '<p>Extant: 1 valid species</p>'
    end

    it "formats a species's statistics correctly" do
      statistics = {
        extant: { subspecies: { 'valid' => 1 } }
      }
      expect(described_class[statistics]).to eq '<p>Extant: 1 valid subspecies</p>'
    end

    context "when there is no valid rank statistics" do
      context "when there is invalid rank statistics" do
        it "appends '0 valid' before the invalid rank statistics" do
          statistics = {
            extant: { subspecies: { 'synonym' => 1 } }
          }
          expect(described_class[statistics]).to eq '<p>Extant: 0 valid subspecies (1 synonym)</p>'
        end
      end
    end

    it "doesn't pluralize certain statuses" do
      statistics = {
        extant: {
          species: {
            'valid' => 2,
            'synonym' => 2,
            'homonym' => 2,
            'unavailable' => 2,
            'excluded from Formicidae' => 2
          }
        }
      }
      expect(described_class[statistics]).
        to eq '<p>Extant: 2 valid species (2 synonyms, 2 homonyms, 2 unavailable, 2 excluded from Formicidae)</p>'
    end
  end
end
