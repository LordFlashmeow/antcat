require 'rails_helper'

describe ReferencesController do
  describe "forbidden actions" do
    context "when not signed in" do
      specify { expect(get(:new)).to redirect_to_signin_form }
      specify { expect(get(:edit, params: { id: 1 })).to redirect_to_signin_form }
      specify { expect(post(:create)).to redirect_to_signin_form }
      specify { expect(put(:update, params: { id: 1 })).to redirect_to_signin_form }
    end

    context "when signed in as a helper editor" do
      before { sign_in create(:user, :helper) }

      specify { expect(delete(:destroy, params: { id: 1 })).to have_http_status :forbidden }
    end
  end

  describe "GET index" do
    specify { expect(get(:index)).to render_template :index }

    it "assigns @references" do
      reference = create :article_reference
      get :index
      expect(assigns(:references)).to eq [reference]
    end
  end

  describe "POST create" do
    let!(:reference_params) do
      {
        title: 'New Ants',
        citation_year: '1999b',
        author_names_string: "Batiatus, B.; Glaber, G.",
        journal_name: 'Zootaxa',
        series_volume_issue: '6',
        date: "19991220",
        doi: "10.10.1038/nphys117",
        bolton_key: "Smith, 1858b",
        public_notes: "Public notes",
        editor_notes: "Editor notes",
        taxonomic_notes: "Taxonomic notes"
      }
    end
    let!(:params) do
      {
        reference_type: 'ArticleReference',
        article_pagination: '5',
        reference: reference_params
      }
    end

    before { sign_in create(:user, :helper) }

    it 'creates a reference' do
      expect { post(:create, params: params) }.to change { Reference.count }.by(1)

      reference = Reference.last
      expect(reference.title).to eq reference_params[:title]
      expect(reference.citation_year).to eq reference_params[:citation_year]
      expect(reference.year).to eq 1999

      expect(reference.author_names_string).to eq reference_params[:author_names_string]

      expect(reference.journal.name).to eq reference_params[:journal_name]
      expect(reference.series_volume_issue).to eq reference_params[:series_volume_issue]

      expect(reference.date).to eq reference_params[:date]
      expect(reference.doi).to eq reference_params[:doi]
      expect(reference.bolton_key).to eq reference_params[:bolton_key]
      expect(reference.public_notes).to eq reference_params[:public_notes]
      expect(reference.editor_notes).to eq reference_params[:editor_notes]
      expect(reference.taxonomic_notes).to eq reference_params[:taxonomic_notes]
    end

    it 'creates an activity' do
      expect { post(:create, params: params.merge(edit_summary: 'edited')) }.
        to change { Activity.where(action: :create).count }.by(1)

      activity = Activity.last
      reference = Reference.last
      expect(activity.trackable).to eq reference
      expect(activity.edit_summary).to eq "edited"
      expect(activity.parameters).to eq(name: "Batiatus & Glaber, 1999b")
    end
  end

  describe "PUT update" do
    let!(:reference) { create :article_reference }
    let!(:reference_params) do
      {
        title: 'Newer Ants',
        author_names_string: reference.author_names_string,
        journal_name: reference.journal.name
      }
    end
    let!(:params) do
      {
        reference_type: reference.type,
        article_pagination: '5',
        id: reference.id,
        reference: reference_params
      }
    end

    before { sign_in create(:user, :helper) }

    it 'updates the reference' do
      put(:update, params: params)

      reference.reload
      expect(reference.title).to eq reference_params[:title]
    end

    it 'creates an activity' do
      expect { put(:update, params: params.merge(edit_summary: 'edited')) }.
        to change { Activity.where(action: :update, trackable: reference).count }.by(1)

      activity = Activity.last
      expect(activity.edit_summary).to eq 'edited'
      expect(activity.parameters).to eq(name: reference.keey)
    end
  end

  describe "DELETE destroy" do
    let!(:reference) { create :unknown_reference }

    before { sign_in create(:user, :editor) }

    it 'deletes the reference' do
      expect { delete(:destroy, params: { id: reference.id }) }.to change { Reference.count }.by(-1)
    end

    it 'creates an activity' do
      reference_keey = reference.keey

      expect { delete(:destroy, params: { id: reference.id, edit_summary: 'Duplicate' }) }.
        to change { Activity.where(action: :destroy, trackable: reference).count }.by(1)

      activity = Activity.last
      expect(activity.edit_summary).to eq "Duplicate"
      expect(activity.parameters).to eq(name: reference_keey)
    end
  end
end
