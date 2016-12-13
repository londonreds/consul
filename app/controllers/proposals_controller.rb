class ProposalsController < ApplicationController
  include CommentableActions
  include FlagActions

  before_action :parse_search_terms, only: [:index, :suggest]
  before_action :parse_advanced_search_terms, only: :index
  before_action :parse_tag_filter, only: :index
  before_action :set_search_order, only: :index
  before_action :load_categories, only: [:index, :new, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary]

  before_action :set_paper_trail_whodunnit

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  # controls proposal sorting options
  # whichever you put first becomes the default
  # possible values: hot_score confidence_score created_at relevance archival_date random and maybe more?
  has_orders %w{random created_at hot_score confidence_score}, only: :index

  # controls comment sorting options
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  def show
    super
    @notifications = @proposal.notifications
    redirect_to proposal_path(@proposal), status: :moved_permanently if request.path != proposal_path(@proposal)
  end

  def update
    super

    ProposalNotifier.new(proposal: @proposal).process

    @proposal.voters.each do |voter|
      Notification.add(voter.id, @proposal) unless voter.id == @proposal.author.id
    end
  end

  def index_customization
    discard_archived
    load_retired
    load_proposal_ballots
    load_featured unless @proposal_successfull_exists
  end

  def vote
    @proposal.register_vote(current_user, 'yes')
    set_proposal_votes(@proposal)
  end

  def unvote
    @proposal.unregister_vote(current_user)
    set_proposal_votes(@proposal)
  end

  def retire
    if valid_retired_params? && @proposal.update(retired_params.merge(retired_at: Time.now))
      redirect_to proposal_path(@proposal), notice: t('proposals.notice.retired')
    else
      render action: :retire_form
    end
  end

  def retire_form
  end

  def vote_featured
    @proposal.register_vote(current_user, 'yes')
    set_featured_proposal_votes(@proposal)
  end

  def summary
    @proposals = Proposal.for_summary
    @tag_cloud = tag_cloud
  end

  private

    def proposal_params
      params.require(:proposal).permit(:title, :question, :summary, :description, :external_url, :video_url, :responsible_name, :tag_list, :terms_of_service, :geozone_id)
    end

    def retired_params
      params.require(:proposal).permit(:retired_reason, :retired_explanation)
    end

    def valid_retired_params?
      @proposal.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:proposal][:retired_reason].blank?
      @proposal.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:proposal][:retired_explanation].blank?
      @proposal.errors.empty?
    end

    def resource_model
      Proposal
    end

    def set_featured_proposal_votes(proposals)
      @featured_proposals_votes = current_user ? current_user.proposal_votes(proposals) : {}
    end

    def discard_archived
      @resources = @resources.not_archived unless @current_order == "archival_date"
    end

    def load_retired
      if params[:retired].present?
        @resources = @resources.retired
        @resources = @resources.where(retired_reason: params[:retired]) if Proposal::RETIRE_OPTIONS.include?(params[:retired])
      else
        @resources = @resources.not_retired
      end
    end

    def load_featured
      # @featured_proposals = Proposal.not_archived.sort_by_confidence_score.limit(3) if (!@advanced_search_terms && @search_terms.blank? && @tag_filter.blank? && params[:retired].blank?)
      if @featured_proposals.present?
        set_featured_proposal_votes(@featured_proposals)
        @resources = @resources.where('proposals.id NOT IN (?)', @featured_proposals.map(&:id))
      end
    end

    def load_proposal_ballots
      @proposal_successfull_exists = Proposal.successfull.exists?
    end

end
