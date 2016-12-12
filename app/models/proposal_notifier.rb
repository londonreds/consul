class ProposalNotifier
  def initialize(args = {})
    @proposal = args.fetch(:proposal)
    @author  = @proposal.author
  end

  def process
    send_email_to_supporters
    send_email_to_commenters
  end

  private

  def send_email_to_commenters
    unique_commenters = @proposal.comments.collect(&:author).uniq{|author| author.id}

    unique_commenters.each do | commenter |
      if @proposal.author.id == commenter.id
        next
      end

      ProposalMailer.edit(commenter, @proposal).deliver_later if email_on_comment?
    end
  end

  def send_email_to_supporters
    @proposal.voters.each  do | voter |
      ProposalMailer.edit(voter, @proposal).deliver_later if email_on_edit?
    end
  end

  def email_on_edit?
    true
  end

  def email_on_comment?
    true
  end
end
