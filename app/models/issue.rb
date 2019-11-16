class Issue < ApplicationRecord
  include HasUserNotifications
  include RevisionsCanBeCompared
  include Trackable

  belongs_to :adder, class_name: "User"
  belongs_to :closer, class_name: "User"

  validates :adder, :description, presence: true
  validates :title, presence: true, length: { maximum: 70 }

  scope :open, -> { where(open: true) }
  scope :by_status_and_date, -> { order(open: :desc, created_at: :desc) }

  acts_as_commentable
  has_paper_trail
  trackable parameters: proc { { title: title } }

  def closed?
    !open?
  end

  def close! user
    update!(open: false, closer: user)
  end

  def reopen!
    update!(open: true, closer: nil)
  end

  # Read-only alias for `Comment#notify_commentable_creator`.
  def user
    adder
  end
end
