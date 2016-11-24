FROM eu.gcr.io/momentum-mxv/base

# crontab setup - the cron jobs need the same codebase as the app
# so they can run rake tasks so we bake the cron stuff into the app image

RUN apt-get install -y python-setuptools
RUN easy_install pip
RUN pip install https://bitbucket.org/dbenamy/devcron/get/tip.tar.gz
ADD ./cron/crontab /cron/crontab
ADD ./cron/rake.sh /app/rake.sh
RUN chmod a+x /app/rake.sh

# these layers are split so that pushing new images does need a 30mb upload
# each time (which will be less painful when we have CI)

# things that rarely change

ADD ./public /app/public
ADD ./vendor /app/vendor
ADD ./bin /app/bin
ADD ./Rakefile /app/Rakefile
ADD ./config.ru /app/config.ru
ADD ./scripts/run.sh /app/scripts/run.sh
ADD ./scripts/cronrun.sh /app/scripts/cronrun.sh

# put these folders in order of least-frequently changing first

ADD ./config /app/config
ADD ./db /app/db
ADD ./lib /app/lib
ADD ./app /app/app
ADD ./version /app/version
