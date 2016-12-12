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
    ProposalMailer.edit(@proposal).deliver_later if email_on_edit?
  end

  def email_on_edit?
    true
  end

end
