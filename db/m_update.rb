require 'json'
require 'securerandom'
require 'open-uri'

require_relative 'create_user'

# invoke with   rake db:m_update json=http://www.example.com/json-endpoint?token=abcxyz

puts "Updating users"

json_data = open(ENV['json'])
members = JSON.parse(json_data.read)

# this top part is adapted for json
members.each do |row|

  email = row['email']
  firstname = row['firstname']
  lastname = row['lastname']
  mem_number = row['mem_number']
  
  email.squish!   # trim leading/trailing spaces - needed for dupe detection

  unless User.exists?(:email => email)

    username = firstname.titleize + " " + lastname.titleize

    if User.exists?(:username => username)

      puts "Username already taken: #{username}"
      
      i = 2
      username_text = username
      # ie once we find a username that's not taken, leave this loop
      while User.exists?(:username => username) 
        username = username_text + " " + i.to_s
        i += 1
      end
      
      puts "Using username: #{username}"

    end

    begin
      user = create_user(email, username) 
      puts "Created #{username}"
      level = 3
      mem_number = 1111111111 if mem_number.nil?  # fallback - seems to need fake document number to allow proposal creation 
      user.update(verified_at: Time.now, document_number: mem_number ) 
    rescue
      puts "#{$!}"
    end
      # todo: email the user (use 'forgot password' links)
  
  else

    puts "Email already taken: #{email}"

  end

end

