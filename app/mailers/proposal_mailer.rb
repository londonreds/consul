class ProposalMailer < ApplicationMailer
  helper :text_with_links
  helper :mailer
  helper :users

  def edit(proposal)
    @proposal = proposal
    @voters = proposal.voters

    @voters.each  do | voter |
      with_user(voter) do
        mail(to: voter.email, subject: 'Test')
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
