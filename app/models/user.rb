# TODO column for `devise :invitable` can be removed from the db.

class User < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include Feed::Trackable

  has_many :activities, class_name: "Feed::Activity"
  has_many :comments
  has_many :notifications, -> { order(id: :desc) }
  has_many :unseen_notifications, -> { unseen }, class_name: "Notification"

  validates :name, presence: true

  scope :order_by_name, -> { order(:name) }
  scope :editors, -> { where(can_edit: true) }
  scope :non_editors, -> { where(can_edit: [false, nil]) } # TODO only allow true/false?
  scope :as_angle_bracketed_emails, -> { all.map(&:angle_bracketed_email).join(", ") }

  acts_as_reader
  devise :database_authenticatable, :recoverable, :registerable,
    :rememberable, :trackable, :validatable
  tracked on: :create, parameters: proc { { user_id: id } }

  def self.current
    RequestStore.store[:current_user]
  end

  def self.current=(user)
    RequestStore.store[:current_user] = user
  end

  def can_approve_changes?
    can_edit?
  end

  def can_review_changes?
    can_edit?
  end

  def angle_bracketed_email
    %Q["#{name}" <#{email}>]
  end

  def notify_because(reason, attached:, notifier:)
    return if notifier == self
    return if already_notified_for_attached_by_user? attached, notifier

    Notification.create! user: self, reason: reason, attached: attached, notifier: notifier
  end

  def mark_unseen_notifications_as_seen
    unseen_notifications.update_all seen: true
  end

  # For at.js.
  def mentionable_search_key
    "#{id} #{name} #{email}"
  end

  private
    # To avoid sending repeated notifications eg when a comment that
    # already mentions a user is edited and saved again.
    def already_notified_for_attached_by_user? attached, mentioner
      notifications.where(notifier: mentioner, attached: attached).exists?
    end
end
