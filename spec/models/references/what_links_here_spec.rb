# frozen_string_literal: true

require 'rails_helper'

describe References::WhatLinksHere do
  subject(:what_links_here) { described_class.new(reference.reload) }

  let(:reference) { create :any_reference }

  context 'when there are no references' do
    specify { expect(what_links_here.all).to eq [] }
    specify { expect(what_links_here.any?).to eq false }
  end

  context 'when there are column references' do
    let!(:taxon) { create :family }
    let!(:nested_reference) { create :nested_reference, nesting_reference: reference }
    let!(:type_name) { create :type_name, :by_subsequent_designation_of, reference: reference }

    before do
      taxon.protonym.authorship.update!(reference: reference)
    end

    specify do
      expect(what_links_here.all).to match_array [
        WhatLinksHereItem.new('citations',  :reference_id,         taxon.protonym.authorship.id),
        WhatLinksHereItem.new('references', :nesting_reference_id, nested_reference.id),
        WhatLinksHereItem.new('type_names', :reference_id,         type_name.id)
      ]
    end

    specify { expect(what_links_here.any?).to eq true }
  end

  context 'when there are taxt references' do
    describe "tag: `ref`" do
      let(:ref_tag) { "{ref #{reference.id}}" }

      let!(:citation) { create :citation, reference: reference, notes_taxt: ref_tag }
      # TODO: Remove - keyword:type_taxt.
      let!(:taxon) do
        create :genus, type_taxon: create(:family), headline_notes_taxt: ref_tag,
          type_taxt: ", by subsequent designation of {ref #{reference.id}}: 1."
      end
      let!(:history_item) { taxon.history_items.create!(taxt: ref_tag) }
      let!(:reference_section) { create :reference_section, title_taxt: ref_tag, subtitle_taxt: ref_tag, references_taxt: ref_tag }

      specify do
        expect(what_links_here.all).to match_array [
          WhatLinksHereItem.new('taxa',                :type_taxt,           taxon.id),
          WhatLinksHereItem.new('taxa',                :headline_notes_taxt, taxon.id),
          WhatLinksHereItem.new('citations',           :notes_taxt,          citation.id),
          WhatLinksHereItem.new('citations',           :reference_id,        citation.id),
          WhatLinksHereItem.new('reference_sections',  :title_taxt,          reference_section.id),
          WhatLinksHereItem.new('reference_sections',  :subtitle_taxt,       reference_section.id),
          WhatLinksHereItem.new('reference_sections',  :references_taxt,     reference_section.id),
          WhatLinksHereItem.new('taxon_history_items', :taxt,                history_item.id)
        ]
      end

      specify { expect(what_links_here.any?).to eq true }
    end
  end
end
