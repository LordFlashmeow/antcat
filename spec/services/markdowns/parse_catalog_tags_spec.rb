# frozen_string_literal: true

require 'rails_helper'

describe Markdowns::ParseCatalogTags do
  include TestLinksHelpers

  describe "#call" do
    context 'with unsafe tags' do
      it "does not remove them" do
        content = "<i>italics<i><i><script>xss</script></i>"
        expect(described_class[content]).to eq content
      end
    end

    describe "tag: `TAX_TAG_REGEX`" do
      it "uses the HTML version of the taxon's name" do
        taxon = create :genus
        expect(described_class["{tax #{taxon.id}}"]).to eq taxon_link(taxon)
      end

      context "when taxon does not exists" do
        it "adds a warning" do
          expect(described_class["{tax 999}"]).to include "CANNOT FIND TAXON FOR TAG {tax 999}"
        end
      end
    end

    describe "tag: `TAXAC_TAG_REGEX`" do
      it "uses the HTML version of the taxon's name" do
        taxon = create :genus
        expect(described_class["{taxac #{taxon.id}}"]).to eq <<~HTML.squish
          #{taxon_link(taxon)}
          <span class="discret-author-citation">#{taxon_authorship_link(taxon)}</span>
        HTML
      end

      context "when taxon does not exists" do
        it "adds a warning" do
          expect(described_class["{taxac 999}"]).to include "CANNOT FIND TAXON FOR TAG {taxac 999}"
        end
      end
    end

    describe "tag: `PRO_TAG_REGEX`" do
      it "uses the HTML version of the protonyms's name" do
        protonym = create :protonym
        expect(described_class["{pro #{protonym.id}}"]).to eq protonym_link(protonym)
      end

      context "when protonym does not exists" do
        it "adds a warning" do
          expect(described_class["{pro 999}"]).to include "CANNOT FIND PROTONYM FOR TAG {pro 999}"
        end
      end
    end

    describe "tag: `PROAC_TAG_REGEX`" do
      it "uses the HTML version of the protonyms's name" do
        protonym = create :protonym
        expect(described_class["{proac #{protonym.id}}"]).to eq <<~HTML.squish
          #{protonym_link(protonym)}
          <span class="discret-author-citation">#{reference_link(protonym.authorship_reference)}</span>
        HTML
      end

      context "when protonym does not exists" do
        it "adds a warning" do
          expect(described_class["{proac 999}"]).to include "CANNOT FIND PROTONYM FOR TAG {proac 999}"
        end
      end
    end

    describe "tag: `PROTT_TAG_REGEX`" do
      context "when protonym has a `terminal_taxon`" do
        let!(:protonym) { create :protonym, :genus_group_name }
        let!(:terminal_taxon) { create :genus, protonym: protonym }

        it "links the terminal taxon" do
          expect(described_class["{prott #{protonym.id}}"]).to eq taxon_link(terminal_taxon)
        end
      end

      context "when protonym does not have a `terminal_taxon`" do
        let!(:protonym) { create :protonym }

        it "links the protonym with a note" do
          expect(described_class["{prott #{protonym.id}}"]).to eq <<~HTML.squish
            #{protonym_link(protonym)} (protonym)
            <span class="logged-in-only-bold-warning">protonym has no terminal taxon</span>
          HTML
        end
      end

      context "when protonym does not exists" do
        it "adds a warning" do
          expect(described_class["{prott 999}"]).to include "CANNOT FIND PROTONYM FOR TAG {prott 999}"
        end
      end
    end

    describe "tag: `PROTTAC_TAG_REGEX`" do
      context "when protonym has a `terminal_taxon`" do
        let!(:protonym) { create :protonym, :genus_group_name }
        let!(:terminal_taxon) { create :genus, protonym: protonym }

        it "links the terminal taxon (with author citation)" do
          expect(described_class["{prottac #{protonym.id}}"]).to eq <<~HTML.squish
            #{taxon_link(terminal_taxon)}
            <span class="discret-author-citation">#{taxon_authorship_link(terminal_taxon)}</span>
          HTML
        end
      end

      context "when protonym does not have a `terminal_taxon`" do
        let!(:protonym) { create :protonym }

        it "links the protonym with a note" do
          expect(described_class["{prottac #{protonym.id}}"]).to eq <<~HTML.squish
            #{protonym_link(protonym)} (protonym)
            <span class="logged-in-only-bold-warning">protonym has no terminal taxon</span>
          HTML
        end
      end

      context "when protonym does not exists" do
        it "adds a warning" do
          expect(described_class["{prottac 999}"]).to include "CANNOT FIND PROTONYM FOR TAG {prottac 999}"
        end
      end
    end

    describe "tag: `REF_TAG_REGEX`" do
      context 'when reference has an expandable_reference_cache' do
        let(:reference) { create :any_reference }

        it 'links the reference' do
          reference.decorate.expandable_reference
          expect(reference.expandable_reference_cache).to_not eq nil
          expect(described_class["{ref #{reference.id}}"]).to eq reference_taxt_link(reference)
        end
      end

      context 'when reference has no expandable_reference_cache' do
        let(:reference) { create :any_reference }

        it 'generates it' do
          expect(reference.expandable_reference_cache).to eq nil
          expect(described_class["{ref #{reference.id}}"]).to eq reference_taxt_link(reference)
        end
      end

      context "when reference does not exists" do
        it "adds a warning" do
          expect(described_class["{ref 999}"]).to include "CANNOT FIND REFERENCE FOR TAG {ref 999}"
        end
      end
    end

    describe "tag: `MISSING_TAG_REGEX`" do
      it 'renders the hardcoded name' do
        expect(described_class["Synonym of {missing <i>Atta</i>}"]).
          to eq 'Synonym of <span class="logged-in-only-bold-warning"><i>Atta</i></span>'

        expect(described_class["in family {missing Ecitoninae}"]).
          to eq 'in family <span class="logged-in-only-bold-warning">Ecitoninae</span>'

        expect(described_class["in family {missing2 Ecitoninae}"]).
          to eq 'in family <span class="logged-in-only-bold-warning">Ecitoninae</span>'
      end
    end

    describe "tag: `UNMISSING_TAG_REGEX`" do
      it 'renders the hardcoded name' do
        expect(described_class["Homonym of {unmissing <i>Decamera</i>}"]).
          to eq 'Homonym of <span class="logged-in-only-gray-bold-notice"><i>Decamera</i></span>'

        expect(described_class["in family {unmissing Pices}"]).
          to eq 'in family <span class="logged-in-only-gray-bold-notice">Pices</span>'
      end
    end

    describe "tag: `MISSPELLING_TAG_REGEX`" do
      it 'renders the hardcoded name' do
        expect(described_class["Homonym of {misspelling <i>Decamera</i>}"]).
          to eq 'Homonym of <span class="logged-in-only-gray-bold-notice"><i>Decamera</i></span>'

        expect(described_class["in family {misspelling Pices}"]).
          to eq 'in family <span class="logged-in-only-gray-bold-notice">Pices</span>'
      end
    end

    describe "tag: `HIDDENNOTE_TAG_REGEX`" do
      it 'wraps the note content in a span only visible to logged-in users' do
        expect(described_class["Synonym of Lasius{hiddennote check reference} and Formica"]).
          to eq 'Synonym of Lasius<span class="taxt-hidden-note"><b>Hidden editor note:</b> check reference</span> and Formica'
      end
    end
  end
end
