# frozen_string_literal: true

require 'rails_helper'

describe Taxa::ReorderReferenceSectionsController do
  describe "forbidden actions" do
    context "when signed in as a user", as: :user do
      specify { expect(post(:create, params: { taxa_id: 1 })).to have_http_status :forbidden }
    end
  end

  describe "POST create", as: :editor do
    let(:taxon) { create :any_taxon }
    let(:reordered_ids) { [second.id.to_s, first.id.to_s] }
    let!(:first) { taxon.reference_sections.create! }
    let!(:second) { taxon.reference_sections.create! }

    it "calls `Taxa::Operations::ReorderReferenceSections`" do
      expect(Taxa::Operations::ReorderReferenceSections).to receive(:new).with(taxon, reordered_ids).and_call_original
      post :create, params: { taxa_id: taxon.id, reference_section: reordered_ids }
    end

    it "reorders the reference sections" do
      expect { post :create, params: { taxa_id: taxon.id, reference_section: reordered_ids } }.
        to change { taxon.reference_sections.pluck(:id) }.to([second.id, first.id])
    end

    it 'creates an activity' do
      expect { post(:create, params: { taxa_id: taxon.id, reference_section: reordered_ids }) }.
        to change { Activity.where(action: Activity::REORDER_REFERENCE_SECTIONS).count }.by(1)

      activity = Activity.last
      expect(activity.trackable).to eq taxon
    end
  end
end
