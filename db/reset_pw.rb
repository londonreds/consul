
User.all.each do |user|
  user.send_reset_password_instructions if user.sign_in_count == 0
end
