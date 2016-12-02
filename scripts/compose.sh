#!/bin/bash -e

set -e

#
# scripts that help deploy the app to the local minikube cluster

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/vars.sh
source ${DIR}/utils.sh

function url() {
  echo http://127.0.0.1:${COMPOSE_PORT}
}

function build() {
  docker build -t eu.gcr.io/momentum-mxv/base -f Dockerfile.base .
  docker-compose build
}

function initialize() {
  echo "start postgres"
  docker-compose up -d postgres
  echo "wait for postgres"
  sleep 20
  echo "run db initialize"
  export EXTRA_APP_DOCKER_ARGS="-e DEV_SEED=1"
  app-command bash scripts/initialize.sh
  docker-compose stop postgres
}

function postgres-command() {
  docker run -it --rm ${EXTRA_POSTGRES_DOCKER_ARGS} \
    --network consul_default \
    --link consul_postgres:postgres \
    -e PGPASSWORD=${POSTGRES_SERVICE_PASSWORD} \
    postgres $@
}

function postgres-cli() {
  postgres-command "psql -h postgres -U consul"
}

function app-command() {
  docker run -it --rm ${EXTRA_APP_DOCKER_ARGS} \
    --network consul_default \
    --link consul_postgres:postgres \
    -v ${DIR}/../scripts:/app/scripts \
    -e POSTGRES_SERVICE_HOST=${POSTGRES_SERVICE_HOST} \
    -e POSTGRES_SERVICE_USER=${POSTGRES_SERVICE_USER} \
    -e POSTGRES_SERVICE_PASSWORD=${POSTGRES_SERVICE_PASSWORD} \
    -e POSTGRES_SERVICE_DATABASE=${POSTGRES_SERVICE_DATABASE} \
    consul_app \
    $@
}

function app-assets() {
  export EXTRA_APP_DOCKER_ARGS="-e RAILS_ENV=production -v ${DIR}/../public/assets:/app/public/assets"
  app-command bash scripts/assets.sh
}

function app-cli() {
  app-command bash
}

# this is different to app-command in that it execs into the already
# running app container and does not spawn a new one (like run does)
function app-exec() {
  docker exec -ti --rm consul_app bash
}

function usage() {
cat <<EOF
Usage:
  build                build the images
  url                  print the url to view the app in a browser
  initialize           setup the database the first time
  app-cli              get a bash cli inside a new, connected app container
  app-exec             get a bash cli inside the existing, running app container
  app-assets           compile the app assets for production
  postgres-cli         get a psql cli connected to Postgres
  help                 display this message
EOF
  exit 1
}

function main() {
  case "$1" in
  build)            shift; build $@;;
  url)              shift; url $@;;
  initialize)       shift; initialize $@;;
  app-cli)          shift; app-cli $@;;
  app-exec)         shift; app-exec $@;;
  app-assets)       shift; app-assets $@;;
  postgres-cli)     shift; postgres-cli $@;;
  *)                usage $@;;
  esac
}

main "$@"
