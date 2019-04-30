class ChangeDecorator < Draper::Decorator
  delegate_all

  def format_adder_name
    user_verb = case change.change_type
                when "create" then "added"
                when "delete" then "deleted"
                else               "changed"
                end

    "#{format_changed_by} #{user_verb}".html_safe
  end

  def format_changed_by
    format_username change.changed_by
  end

  def format_approved_by
    format_username change.approver
  end

  def format_created_at
    format_time_ago change.created_at
  end

  def format_approved_at
    return unless change.approved_at?
    format_time_ago change.approved_at
  end

  def approve_button taxon
    return helpers.dash if taxon.approved?

    if can_be_approved_by?(taxon, helpers.current_user)
      helpers.link_to 'Approve', helpers.approve_change_path(change),
        method: :put, class: "btn-saves btn-tiny",
        data: { confirm: "Are you sure you want to approve this change?" }
    end
  end

  def can_be_approved_by? taxon, user
    return false unless taxon.waiting?
    user != change.changed_by
  end

  private

    def format_username user
      return "Someone" unless user # Sometimes we get here with a nil user.
      user.decorate.user_page_link
    end

    def format_time_ago time
      "#{helpers.time_ago_in_words time} ago"
    end
end
