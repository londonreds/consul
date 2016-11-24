namespace :tools do
  desc "switch logger to stdout"
  task :stdoutlogger => [:environment] do
    Rails.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
  desc "print hello to test the cron logging"
  task :helloworld => [:environment] do
    puts "hello world"
  end
end
