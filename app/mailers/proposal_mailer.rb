class ProposalMailer < ApplicationMailer
  helper :text_with_links
  helper :mailer
  helper :users

  def edit(proposal)
    @proposal = proposal
    @voters = proposal.voters
    @last_version = proposal.versions.last.reify

    @voters.each  do | voter |
      with_user(voter) do
        @voter = voter
        mail(to: voter.email, subject: "Proposal #{@last_version.title} you supported has been changed")
      end
    end
  end

  private

  def with_user(user, &block)
    I18n.with_locale(user.locale) do
      block.call
    end
  end
end
