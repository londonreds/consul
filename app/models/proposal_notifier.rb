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
      @commenter = commenter
      ProposalMailer.edit(commenter, @proposal).deliver_later if email_on_comment?
    end
  end

  def send_email_to_supporters
    @proposal.voters.each  do | voter |
      @current_voter = voter
      ProposalMailer.edit(@current_voter, @proposal).deliver_later if email_on_edit?
    end
  end

  def email_on_edit?
    @current_voter.email_on_proposal_edit?
  end

  def email_on_comment?
    @author != @commenter && @commenter.email_on_proposal_edit_as_commenter?
  end
end
