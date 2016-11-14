require 'csv'
require 'securerandom'
require 'open-uri'

# invoke with eg. rake db:m_seed csv=/consul/db/m.csv
# or rake db:m_seed csv=http://www.example.com/file.csv


puts "Creating Users"

def create_user(email, username)
  pwd = SecureRandom.urlsafe_base64(15)  # random pw A-Z a-z 0-9 and -_
  puts "    #{username} : #{pwd}"
  User.create!(username: username, email: email, password: pwd, password_confirmation: pwd, confirmed_at: Time.now, terms_of_service: "1")
  # bug: one username collision causes script to terminate
end

csv_data = open(ENV['csv'])
members = CSV.parse(csv_data.read)

members.each do |email, firstname, lastname|
  
  username = firstname.downcase + lastname.downcase.slice(0)

  user = create_user(email, username) 
  level = 3
  user.update(verified_at: Time.now, document_number: Faker::Number.number(10) ) # seems to need fake document number to allow proposal creation 

  # todo: email the user (use 'forgot password' links)

end

