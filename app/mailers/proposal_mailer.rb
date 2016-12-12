class ProposalMailer < ApplicationMailer
  helper :text_with_links
  helper :mailer
  helper :users

  def edit(voter, proposal)
    @proposal = proposal
    @last_version = proposal.versions.last.reify
    @voter = voter

    with_user(@voter) do
      mail(to: voter.email, subject: "Proposal #{@last_version.title} you supported has been changed")
    end
  end

  private

  def with_user(user, &block)
    I18n.with_locale(user.locale) do
      block.call
    end
  end
end
