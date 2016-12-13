class ProposalMailer < ApplicationMailer
  helper :text_with_links
  helper :mailer
  helper :users

  def edit(voter, proposal, is_comment = false)
    @proposal = proposal
    @last_version = proposal.versions.last.reify
    @voter = voter
    @is_comment = is_comment

    subject = @is_comment ? "Proposal #{@last_version.title} you commented on has been changed" : "Proposal #{@last_version.title} you supported has been changed"

    with_user(@voter) do
      mail(to: voter.email, subject: subject)
    end
  end

  private

  def with_user(user, &block)
    I18n.with_locale(user.locale) do
      block.call
    end
  end
end
