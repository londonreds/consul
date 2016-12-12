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
  end

  def send_email_to_supporters
    @proposal.voters.each  do | voter |
      ProposalMailer.edit(voter, @proposal).deliver_later if email_on_edit?
    end
  end

  def email_on_edit?
    true
  end

end
