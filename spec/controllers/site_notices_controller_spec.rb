require "spec_helper"

describe SiteNoticesController do
  let!(:editor) { create :editor }

  before do
    sign_in editor
    @request.env["HTTP_REFERER"] = "http://antcat.org"
  end

  describe "GET show" do
    let!(:site_notice) { create :site_notice }

    before do
      # TODO this may be safe to remove or replaced with `travel_to`.
      # I believe I added it because the `unread` gem's use of timestamps caused issues.
      sleep 1 # HACK
      @another_site_notice = create :site_notice
    end

    it "marks as read" do
      expect { get :show, id: @another_site_notice.id }
        .to change { SiteNotice.unread_by(editor).count }.by -1
    end
  end

  describe "POST #mark_all_as_read" do
    after { post :mark_all_as_read }

    it "calls SiteNotice" do
      expect(SiteNotice).to receive(:mark_as_read!).with(:all, for: editor)
    end
  end

  describe "POST dismiss" do
    let!(:site_notice) { create :site_notice }

    before { post :dismiss }

    it { is_expected.to set_session[:last_dismissed_site_notice_id].to site_notice.id }
  end
end