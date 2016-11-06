require 'csv'
require 'securerandom'

puts "Creating Users"

def create_user(email, username)
  pwd = SecureRandom.urlsafe_base64(15)  # random pw A-Z a-z 0-9 and -_
  puts "    #{username} : #{pwd}"
  User.create!(username: username, email: email, password: pwd, password_confirmation: pwd, confirmed_at: Time.now, terms_of_service: "1")
end

members = CSV.read("/Users/Tom/Desktop/consul/db/m.csv")

members.each do |email, firstname, lastname|
  
  username = firstname.downcase + lastname.downcase.slice(0)

  user = create_user(email, username) 
  level = 3
  user.update(verified_at: Time.now, document_number: Faker::Number.number(10) )

  # todo: email the user

end

