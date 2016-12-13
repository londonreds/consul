class Notification < ActiveRecord::Base
  belongs_to :user, counter_cache: true
  belongs_to :notifiable, polymorphic: true

  scope :unread,      -> { all }
  scope :recent,      -> { order(id: :desc) }
  scope :not_emailed, -> { where(emailed_at: nil) }
  scope :for_render,  -> { includes(:notifiable) }


  def timestamp
    notifiable.created_at
  end

  def mark_as_read
    self.destroy
  end

  def self.add(user_id, notifiable)
    if notification = Notification.find_by(user_id: user_id, notifiable: notifiable)
      Notification.increment_counter(:counter, notification.id)
    else
      Notification.create!(user_id: user_id, notifiable: notifiable)
    end
  end

  def notifiable_title
    case notifiable.class.name
    when "ProposalNotification"
      notifiable.proposal.title
    when "Proposal"
      notifiable.title
    when "PaperTrail::Version"
      notifiable.item.title
    when "Comment"
      notifiable.commentable.title
    else
      notifiable.title
    end
  end

  def notifiable_action
    case notifiable_type
    when "ProposalNotification"
      "proposal_notification"
    when "PaperTrail::Version"
      "edited"
    when "Comment"
      "replies_to"
    else
      "comments_on"
    end
  end

  def linkable_resource
    if notifiable.is_a?(ProposalNotification)
      notifiable.proposal
    elsif notifiable.is_a?(PaperTrail::Version)
      notifiable.item
    else
      notifiable
    end
  end
end
