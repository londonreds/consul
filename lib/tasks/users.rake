namespace :users do

  desc "Recalculates all the failed census calls counters for users"
  task count_failed_census_calls: :environment do
    User.find_each{ |user| User.reset_counters(user.id, :failed_census_calls)}
  end

  desc "Assigns official level to users with the officials' email domain"
  task check_for_official_emails: :environment do
    domain = Setting['email_domain_for_officials']

    # We end the task if there is no email domain configured
    if !domain.blank?
      # We filter the mail addresses with SQL to speed up the process
      # The real check will be done by check_if_official_email, however.
      User.where('official_level = 0 and email like ?', "%#{domain}").find_each do |user|
        if user.has_official_email?
          user.add_official_position! (Setting['official_level_1_name']), 1
          puts "#{user.username} (#{user.email}) is now a level-1 official."
        end
      end
    end
  end

  desc "Associates a geozone to each user who doesn't have it already but has validated his residence using the census API"
  task assign_geozones: :environment do
    User.residence_verified.where(geozone_id: nil).find_each do |u|
      begin
        response = CensusApi.new.call(u.document_type, u.document_number)
        if response.valid?
          u.geozone = Geozone.where(census_code: response.district_code).first
          u.save
          print "."
        else
          print "X"
        end
      rescue
        puts "Could not assign geozone for user: #{u.id}"
      end
    end
  end

  desc "Associates demographic information to users"
  task assign_demographic: :environment do
    User.residence_verified.where(gender: nil).find_each do |u|
      begin
        response = CensusApi.new.call(u.document_type, u.document_number)
        if response.valid?
          u.gender = response.gender
          u.date_of_birth = response.date_of_birth.to_datetime
          u.save
          print "."
        else
          print "X"
        end
      rescue
        puts "Could not assign gender/dob for user: #{u.id}"
      end
    end
  end

  desc "Makes duplicate username users change their username"
  task social_network_reset: :environment do
    duplicated_usernames = User.all.select(:username).group(:username).having('count(username) > 1').pluck(:username)

    duplicated_usernames.each do |username|
      print "."
      user_ids = User.where(username: username).order(created_at: :asc).pluck(:id)
      user_ids_to_review = Identity.where(user_id: user_ids).pluck(:user_id)
      user_ids_to_review.shift if user_ids.size == user_ids_to_review.size
      user_ids_to_review.each { |id| User.find(id).update(registering_with_oauth: true) }
    end
  end

  desc "Removes identities associated to erased users"
  task remove_erased_identities: :environment do
    Identity.joins(:user).where('users.erased_at IS NOT NULL').destroy_all
  end

  desc "Update password changed at for existing users"
  task update_password_changed_at: :environment do
    User.all.each do |user|
      user.update(password_changed_at: user.created_at)
    end
  end

  desc 'Create a new user - rake user:new_user firstname="" lastname="" email="" mem_number=""'
  task new_user: :environment do
    load(Rails.root.join("db", "new_user.rb"))
  end

end
