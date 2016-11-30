require "spec_helper"

describe Taxa::ReorderHistoryItems do
  describe "#reorder_history_items" do
    let(:taxon) { create_genus }
    let!(:first) { taxon.history_items.create! taxt: "A" }
    let!(:second) { taxon.history_items.create! taxt: "B" }
    let!(:third) { taxon.history_items.create! taxt: "C" }

    def item_ids_to_s taxon
      taxon.history_items.pluck(:id).map(&:to_s)
    end

    it "*test setup*" do
      expected = [first.id, second.id, third.id].map(&:to_s)
      expect(item_ids_to_s taxon).to eq expected
    end

    context "valid and different" do
      it "updates the positions" do
        reordered_ids = [second.id, third.id, first.id].map(&:to_s)
        expect(item_ids_to_s taxon).to_not eq reordered_ids

        taxon.reorder_history_items reordered_ids
        expect(item_ids_to_s taxon).to eq reordered_ids
      end
    end

    context "valid but not different" do
      it "doesn't update the positions" do
        reordered_ids = [first.id, second.id, third.id].map(&:to_s)
        taxon.reorder_history_items reordered_ids

        error_message = taxon.errors.messages[:history_items]
        expect(error_message).to include /already ordered like this/
      end
    end

    context "reordered ids are invalid" do
      it "doesn't update the positions" do
        reordered_ids = [second.id, third.id, 9999999].map(&:to_s)
        taxon.reorder_history_items reordered_ids

        error_message = taxon.errors.messages[:history_items]
        expect(error_message).to include /doesn't match current IDs/
      end
    end
  end
end
