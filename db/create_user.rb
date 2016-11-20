require 'securerandom'

def create_user(email, username)
  pwd = SecureRandom.urlsafe_base64(25)  # random pw A-Z a-z 0-9 and -_  (not actually used as we send reset tokens)
  User.create!(username: username, email: email, password: pwd, password_confirmation: pwd, confirmed_at: Time.now, terms_of_service: "1")
end
