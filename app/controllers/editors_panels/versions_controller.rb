# frozen_string_literal: true

module EditorsPanels
  class VersionsController < ApplicationController
    FILTER_ITEM_TYPES = %w[
      Activity
      Author
      AuthorName
      Citation
      Comment
      Feedback
      Institution
      Issue
      Journal
      Name
      Place
      Protonym
      Publisher
      Reference
      ReferenceAuthorName
      ReferenceDocument
      ReferenceSection
      SiteNotice
      Synonym
      Taxon
      HistoryItem
      TaxonState
      Tooltip
      WikiPage
    ]

    before_action :ensure_user_is_editor

    def index
      @versions = PaperTrail::Version.without_user_versions
      @versions = @versions.filter_where(filter_params)
      @versions = @versions.search(params[:q], params[:search_type]) if params[:q].present?
      @versions = @versions.order(:id).paginate(page: params[:page], per_page: 50)

      @version_count = PaperTrail::Version.count
    end

    def show
      @version = PaperTrail::Version.without_user_versions.find(params[:id])
    end

    private

      def filter_params
        params.permit(:event, :item_id, :item_type, :request_uuid, :whodunnit)
      end
  end
end
