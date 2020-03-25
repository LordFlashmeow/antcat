require 'rails_helper'

describe Taxa::ReorderHistoryItemsController do
  describe "forbidden actions" do
    context "when signed in as a user", as: :user do
      specify { expect(post(:create, params: { taxa_id: 1 })).to have_http_status :forbidden }
    end
  end

  describe "POST create", as: :editor do
    let(:taxon) { create :family }
    let(:reordered_ids) { [second.id.to_s, first.id.to_s] }
    let!(:first) { taxon.history_items.create!(taxt: "A") }
    let!(:second) { taxon.history_items.create!(taxt: "B") }

    it "calls `Taxa::Operations::ReorderHistoryItems`" do
      expect(Taxa::Operations::ReorderHistoryItems).to receive(:new).with(taxon, reordered_ids).and_call_original
      post :create, params: { taxa_id: taxon.id, taxon_history_item: reordered_ids }
    end

    it "reorders the history items" do
      expect { post :create, params: { taxa_id: taxon.id, taxon_history_item: reordered_ids } }.
        to change { taxon.history_items.pluck(:id) }.to([second.id, first.id])
    end

    it 'creates an activity' do
      expect { post(:create, params: { taxa_id: taxon.id, taxon_history_item: reordered_ids }) }.
        to change { Activity.where(action: :reorder_taxon_history_items).count }.by(1)

      activity = Activity.last
      expect(activity.trackable).to eq taxon
    end
  end
end