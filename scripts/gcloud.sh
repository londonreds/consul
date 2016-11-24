#!/bin/bash -e

set -e

#
# scripts that help deploy the app to the local minikube cluster

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/vars.sh
source ${DIR}/utils.sh

export TEMPLATES=${DIR}/../k8s/templates/prod
export CONSUL_APP_TAG=$(app_version)
export CONSUL_APP_IMAGE=$(gcr_image app)
export CONSUL_NGINX_IMAGE=$(gcr_image nginx)

export K8S_ENV="gcloud"

# a safety switch for the live k8s cluster
export SAFETY_SWITCH_ON=1

#
# gcloud specific utils
#

# this makes sure we are back on the host docker (not the minikube one)
function connect-docker() {
  export DOCKER_HOST=unix:///var/run/docker.sock
  export DOCKER_API_VERSION=
  export DOCKER_TLS_VERIFY=
  export DOCKER_CERT_PATH=
}

function connect-kubectl() {
  gcloud container clusters get-credentials consul-cluster --zone europe-west1-c --project momentum-mxv
}




#
# build
#

function build() {
  check-deployment-version
  connect-gcloud
  gcloud docker -- pull eu.gcr.io/momentum-mxv/base
  build-images
  gcloud docker -- push ${CONSUL_APP_IMAGE}
  gcloud docker -- push ${CONSUL_NGINX_IMAGE}
}

main "$@"