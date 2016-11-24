# a wrapper for rake tasks invoked by cron
# we switch to the correct folder and change the logger to stdout
#
# usage: bash /app/run.sh db:setup

currentdate=`date`
echo "${currentdate} - $@"
cd /app && bin/bundle exec rake RAILS_ENV=production tools:stdoutlogger $@