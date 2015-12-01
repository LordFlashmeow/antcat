# coding: UTF-8
class ReferencesController < ApplicationController
  before_filter :authenticate_editor, except: [:index, :download, :autocomplete]
  skip_before_filter :authenticate_editor, if: :preview?

  def index
    params[:search_selector] ||= 'Search for'
    if ['review', 'new', 'clear'].include? params[:commit]
      params[:q] = ''
    end
    params[:q].strip! if params[:q]
    params[:review] = params[:commit] == 'review'
    params[:whats_new] = params[:commit] == 'new'

    params[:is_author_search] = params[:search_selector] == 'Search for author(s)'

    searching = params[:q].present?
    @endnote_export_all_message = unless searching then <<-"MSG".squish else "" end
        Since there are no search criteria, AntCat will download all twelve
        thousand references. Do you want to continue?
    MSG

    @references = Reference.do_search params
  end

  def endnote_export
    searching = params[:q].present?

    references = if searching
                   Reference.do_search params.merge format: :endnote_export
                 else
                   # Not very pretty and doesn't really belong here, but this is
                   # actually a single SQL query (page takes a couple of seconds load),
                   # which is better than making ~50000 queries (takes minutes).
                   # TODO refactor into the Sunspot search method after figuring out
                   # how to make it ':include' related fields and handle pagination
                   Reference.joins(:author_names)
                     .includes(:journal, :author_names, :document, [{publisher: :place}])
                     .where.not(type: 'MissingReference').all
                 end
    render plain: Exporters::Endnote::Formatter.format(references)
  end

  def download
    document = ReferenceDocument.find params[:id]
    if document.downloadable_by? current_user
      redirect_to document.actual_url
    else
      head 401
    end
  end

  def create
    @reference = new_reference
    save true
  end

  def update
    @reference = get_reference
    save false
  end

  def save new
    begin
      Reference.transaction do
        clear_document_params_if_necessary
        clear_nesting_reference_id unless @reference.kind_of? NestedReference
        parse_author_names_string
        set_journal if @reference.kind_of? ArticleReference
        set_publisher if @reference.kind_of? BookReference
        set_pagination
        # kludge around Rails 3 behavior that uses the type to look up a record - so you can't update the type!
        @reference.update_column :type, @reference.type unless new

        unless @reference.errors.present?
          @reference.update_attributes params[:reference]

          @possible_duplicate = @reference.check_for_duplicate unless params[:possible_duplicate].present?
          unless @possible_duplicate
            @reference.save!
            set_document_host
          end
        end

        raise ActiveRecord::RecordInvalid.new @reference if @reference.errors.present?
      end
    rescue ActiveRecord::RecordInvalid
      @reference[:id] = nil if new
      @reference.instance_variable_set :@new_record, new

    end
    DefaultReference.set session, @reference
    render_json new
  end

  def destroy
    @reference = Reference.find(params[:id])
    if @reference.any_references? or not @reference.destroy
      json = {success: false, message: "This reference can't be deleted, as there are other references to it."}.to_json
    else
      json = {success: true}
    end
    render json: json
  end

  def start_reviewing
    @reference = Reference.find(params[:id])
    @reference.start_reviewing!
    DefaultReference.set session, @reference
    redirect_to '/references?commit=new'
  end

  def finish_reviewing
    @reference = Reference.find(params[:id])
    @reference.finish_reviewing!
    redirect_to '/references?commit=new'
  end

  def restart_reviewing
    @reference = Reference.find(params[:id])
    @reference.restart_reviewing!
    DefaultReference.set session, @reference
    redirect_to '/references?commit=new'
  end

  def approve_all
    Reference.where('review_state != "reviewed"').each  do |reference|
      reference[:review_state]='reviewed'
      reference.save!
    end

    redirect_to '/references?commit=new'
  end

  def autocomplete
    search_query = params[:q] || ''

    search_options = {}
    keyword_params = Reference.send(:extract_keyword_params, search_query)

    search_options[:reference_type] = :nomissing
    search_options[:items_per_page] = 5
    search_options.merge! keyword_params
    search_results = Reference.send(:fulltext_search, search_options)

    respond_to do |format|
      format.json do
        results = search_results.map do |reference|
          search_query = if keyword_params.size == 1 # size 1 = no keyword params were matched
                           reference.title
                         else
                           format_autosuggest_keywords reference, keyword_params
                         end
          {
            search_query: search_query,
            title: reference.title,
            author: reference.author_names_string,
            year: reference.citation_year
          }
        end

        render json: results
      end
    end
  end

  private
  def set_pagination
    params[:reference][:pagination] =
      case @reference
      when ArticleReference then params[:article_pagination]
      when BookReference then params[:book_pagination]
      else nil
      end
  end

  def set_document_host
    @reference.document_host = request.host
  end

  def parse_author_names_string
    author_names_and_suffix = @reference.parse_author_names_and_suffix params[:reference].delete(:author_names_string)
    @reference.author_names.clear
    params[:reference][:author_names] = author_names_and_suffix[:author_names]
    params[:reference][:author_names_suffix] = author_names_and_suffix[:author_names_suffix]
  end

  def set_journal
    @reference.journal_name = params[:reference][:journal_name]
    params[:reference][:journal] = Journal.import @reference.journal_name
  end


  def set_publisher
    @reference.publisher_string = params[:reference][:publisher_string]
    publisher = Publisher.import_string @reference.publisher_string
    if publisher.nil? and @reference.publisher_string.present?
      @reference.errors.add :publisher_string, "couldn't be parsed. In general, use the format 'Place: Publisher'. Otherwise, please post a message on http://groups.google.com/group/antcat/, and we'll see what we can do!"
    else
      params[:reference][:publisher] = publisher
    end
  end

  def clear_nesting_reference_id
    params[:reference][:nesting_reference_id] = nil
  end

  def clear_document_params_if_necessary
    return unless params[:reference][:document_attributes]
    params[:reference][:document_attributes][:id] = nil unless params[:reference][:document_attributes][:url].present?
  end

  def render_json new = false
    template =
    case
      when params[:field].present? then 'reference_fields/panel'
      when params[:picker].present? then 'reference_fields/panel'
      when params[:popup].present? then 'reference_popups/panel'
      else 'references/reference'
    end

    send_back_json(
      isNew: new,
      content: render_to_string(partial: template, locals: {reference: @reference, css_class: 'reference'}),
      id: @reference.id,
      success: @reference.errors.empty?)
  end

  def new_reference
    case params[:selected_tab]
    when 'Article' then ArticleReference.new
    when 'Book' then    BookReference.new
    when 'Nested' then  NestedReference.new
    else                UnknownReference.new
    end
  end

  def get_reference
    selected_tab = params[:selected_tab]
    selected_tab = 'Unknown' if selected_tab == 'Other'
    type = selected_tab + 'Reference'
    reference = Reference.find(params[:id]).becomes((type).constantize)
    reference.type = type
    reference
  end

  def format_autosuggest_keywords reference, keyword_params
    replaced = []
    replaced << keyword_params[:keywords] || ''
    replaced << "author:'#{reference.author_names_string}'" if keyword_params[:author]
    replaced << "year:#{keyword_params[:year]}" if keyword_params[:year]

    start_year = keyword_params[:start_year]
    end_year   = keyword_params[:end_year]
    if start_year && end_year
      replaced << "year:#{start_year}-#{end_year}"
    end
    replaced.join(" ").strip
  end

end
