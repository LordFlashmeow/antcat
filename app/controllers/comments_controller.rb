class CommentsController < ApplicationController
  include HasWhereFilters

  before_action :authenticate_user!
  before_action :ensure_unconfirmed_user_is_not_over_edit_limit, except: [:index]
  before_action :set_comment, only: [:edit, :update]

  has_filters(
    user_id: {
      tag: :select_tag,
      options: -> { User.order(:name).pluck(:name, :id) }
    },
    commentable_type: {
      tag: :select_tag,
      options: -> { %w[Issue Feedback] }
    },
    commentable_id: {
      tag: :number_field_tag
    }
  )

  def index
    @comments = Comment.filter(filter_params)
    @comments = @comments.order_by_date.include_associations.paginate(page: params[:page])
  end

  def create
    @comment = Comment.build_comment commentable, current_user, body: comment_params[:body]
    @comment.set_parent_to = comment_params[:comment_id]

    if @comment.save
      @comment.create_activity :create, current_user
      @comment.notify_relevant_users
      highlighted_comment_url = "#{request.referer}#comment-#{@comment.id}"
      redirect_to highlighted_comment_url, notice: <<-MSG
        <a href="#comment-#{@comment.id}">Comment</a> was successfully added.
      MSG
    else
      redirect_back fallback_location: root_path, notice: "Something went wrong. Email us?"
    end
  end

  def edit
  end

  def update
    @comment.body = comment_params[:body]
    @comment.edited = true

    if @comment.save
      @comment.notify_relevant_users
      redirect_to @comment.commentable, notice: <<-MSG
        <a href="#comment-#{@comment.id}">Comment</a> was successfully updated.
      MSG
    else
      render :edit
    end
  end

  private

    def set_comment
      @comment = current_user.comments.find(params[:id])
    end

    def commentable
      comment_params[:commentable_type].constantize.find(comment_params[:commentable_id])
    end

    def comment_params
      params.require(:comment).permit(:body, :commentable_id, :commentable_type, :comment_id)
    end
end
