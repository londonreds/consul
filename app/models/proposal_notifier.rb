class ProposalNotifier
  def initialize(args = {})
    @proposal = args.fetch(:proposal)
    @author  = @proposal.author
  end

  def process
    send_email_to_supporters
  end

  private

  def send_email_to_supporters
    ProposalMailer.edit(@proposal).deliver_later
    # ProposalMailer.edit(@proposal).deliver_later if email_on_comment?
  end

  def email_on_comment?
    commentable_author = @comment.commentable.author
    commentable_author != @author && commentable_author.email_on_comment?
  end

  def email_on_comment_reply?
    return false unless @comment.reply?
    parent_author = @comment.parent.author
    parent_author != @author && parent_author.email_on_comment_reply?
  end

end
