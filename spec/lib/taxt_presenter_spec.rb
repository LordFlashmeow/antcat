require "spec_helper"

describe TaxtPresenter do
  describe "#to_text" do
    it "renders text without links or HTML (except <i> tags)" do
      taxt = "{tax #{create(:family).id}}"
      expect(described_class[taxt].to_text).to eq "Formicidae"
    end

    context "names that should be italicized" do
      let(:genus) { create :genus }

      it "includes HTML <i> tags" do
        taxt = "{tax #{genus.id}}"
        expect(described_class[taxt].to_text).to eq "<i>#{genus.name.name}</i>"
      end
    end
  end

  describe "#to_html" do
    describe "escaping input" do
      it "doesn't escape already escaped input" do
        reference = create :unknown_reference, citation: 'Latreille, 1809 <script>'
        expected = 'Latreille, 1809 &lt;script&gt;'
        expect(reference.decorate.expandable_reference).to include expected
        expect(described_class["{ref #{reference.id}}"].to_html).to include expected
      end
    end

    it "handles nil" do
      expect(described_class[nil].to_html).to eq ''
    end

    specify { expect(described_class['string'].to_html).to be_html_safe }

    describe "ref tags (references)" do
      context "when the ref tag is malformed" do
        it "doesn't freak" do
          expect(described_class["{ref sdf}"].to_html).to eq '{ref sdf}'
        end
      end

      context "when the ref points to a reference that doesn't exist" do
        let(:results) { described_class["{ref 999}"].to_html }

        it "adds a warning" do
          expect(results).to match "CANNOT FIND REFERENCE WITH ID 999"
        end

        it "includes a 'Search history?' link" do
          expect(results).to match "Search history?"
        end
      end
    end

    describe "nam tags (names)" do
      it "returns the HTML version of the name" do
        name = create :subspecies_name
        expect(described_class["{nam #{name.id}}"].to_html).to eq name.to_html
      end

      context "when the name can't be found" do
        let(:results) { described_class["{nam 999}"].to_html }

        it "adds a warning" do
          expect(results).to match "CANNOT FIND NAME WITH ID 999"
        end

        it "includes a 'Search history?' link" do
          expect(results).to match "Search history?"
        end
      end
    end

    describe "tax tags (taxa)" do
      it "uses the HTML version of the taxon's name" do
        taxon = create :genus
        expect(described_class["{tax #{taxon.id}}"].to_html).
          to eq %(<a href="/catalog/#{taxon.id}"><i>#{taxon.name_cache}</i></a>)
      end

      context "when the taxon is a fossil" do
        let!(:taxon) { create :genus, fossil: true }

        it "includes the fossil symbol" do
          expect(described_class["{tax #{taxon.id}}"].to_html).
            to eq %(<a href="/catalog/#{taxon.id}"><i>&dagger;</i><i>#{taxon.name_cache}</i></a>)
        end
      end

      context "when the taxon can't be found" do
        let(:results) { described_class["{tax 999}"].to_html }

        it "adds a warning" do
          expect(results).to match "CANNOT FIND TAXON WITH ID 999"
        end

        it "includes a 'Search history?' link" do
          expect(results).to match "Search history?"
        end
      end
    end
  end

  describe "#to_antweb" do
    let(:taxt) { "{tax #{create(:family).id}}" }

    it "uses a different link formatter" do
      expect(described_class[taxt].to_antweb).to match "antcat.org"
    end

    describe 'broken taxt tags' do
      describe "ref tags (references)" do
        let(:results) { described_class["{ref 999}"].to_antweb }

        context "when the ref points to a reference that doesn't exist" do
          it "adds a warning" do
            expect(results).to match "CANNOT FIND REFERENCE WITH ID 999"
          end

          it "doesn't include a 'Search history?' link" do
            expect(results).not_to match "Search history?"
          end
        end
      end

      describe "nam tags (names)" do
        context "when the name can't be found" do
          let(:results) { described_class["{nam 999}"].to_antweb }

          it "adds a warning" do
            expect(results).to match "CANNOT FIND NAME WITH ID 999"
          end

          it "doesn't include a 'Search history?' link" do
            expect(results).not_to match "Search history?"
          end
        end
      end

      describe "tax tags (taxa)" do
        let(:results) { described_class["{tax 999}"].to_antweb }

        context "when the taxon can't be found" do
          it "adds a warning" do
            expect(results).to match "CANNOT FIND TAXON WITH ID 999"
          end

          it "doesn't include a 'Search history?' link" do
            expect(results).not_to match "Search history?"
          end
        end
      end
    end
  end
end
