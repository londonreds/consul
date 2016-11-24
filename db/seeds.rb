# coding: utf-8
# Default admin user (change password after first deploy to a server!)
if Administrator.count == 0 && !Rails.env.test?
  admin = User.create!(username: 'admin', email: 'admin@consul.dev', password: 'abcdabcd', password_confirmation: 'abcdabcd', confirmed_at: Time.now, terms_of_service: "1")
  admin.create_administrator
end

# Create Momentum's categories
puts "Creating Categories"

ActsAsTaggableOn::Tag.create!(name:  "Purpose", featured: true, kind: "category")
ActsAsTaggableOn::Tag.create!(name:  "Organisation", featured: true, kind: "category")
ActsAsTaggableOn::Tag.create!(name:  "Ethics", featured: true, kind: "category")

# Names for the moderation console, as a hint for moderators
# to know better how to assign users with official positions
Setting["official_level_1_name"] = "A"
Setting["official_level_2_name"] = "B"
Setting["official_level_3_name"] = "C"
Setting["official_level_4_name"] = "D"
Setting["official_level_5_name"] = "E"

# Max percentage of allowed anonymous votes on a debate
Setting["max_ratio_anon_votes_on_debates"] = 50

# Max votes where a debate is still editable
Setting["max_votes_for_debate_edit"] = 1000

# Max votes where a proposal is still editable
Setting["max_votes_for_proposal_edit"] = 50000

# Max length for comments
Setting['comments_body_max_length'] = 1000

# Prefix for the Proposal codes
Setting["proposal_code_prefix"] = 'MM'

# Number of votes needed for proposal success
Setting["votes_for_proposal_success"] = 50000

# Months to archive proposals
Setting["months_to_archive_proposals"] = 12

# Users with this email domain will automatically be marked as level 1 officials
# Emails under the domain's subdomains will also be included
Setting["email_domain_for_officials"] = ''

# Code to be included at the top (header) of every page (useful for tracking)
Setting['per_page_code'] =  ''

# Social settings
Setting["twitter_handle"] = nil
Setting["twitter_hashtag"] = nil
Setting["facebook_handle"] = nil
Setting["youtube_handle"] = nil
Setting["blog_url"] = nil

# Public-facing URL of the app.
Setting["url"] = "http://mxv.peoplesmomentum.com"

# Consul installation's organization name
Setting["org_name"] = "MxV"

# Consul installation place name (City, Country...)
Setting["place_name"] = "Momentum"

# Feature flags
Setting['feature.debates'] = false
Setting['feature.spending_proposals'] = false
Setting['feature.twitter_login'] = false
Setting['feature.facebook_login'] = false
Setting['feature.google_login'] = false
Setting['feature.public_stats'] = false

# Spending proposals feature flags
Setting['feature.spending_proposal_features.voting_allowed'] = false

# Banner styles
Setting['banner-style.banner-style-one']   = "Banner style 1"
Setting['banner-style.banner-style-two']   = "Banner style 2"
Setting['banner-style.banner-style-three'] = "Banner style 3"

# Banner images
Setting['banner-img.banner-img-one']   = "Banner image 1"
Setting['banner-img.banner-img-two']   = "Banner image 2"
Setting['banner-img.banner-img-three'] = "Banner image 3"

# Proposal notifications
Setting['proposal_notification_minimum_interval_in_days'] = 1
Setting['direct_message_max_per_day'] = 3