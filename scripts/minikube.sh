#!/bin/bash -e

set -e

#
# scripts that help deploy the app to the local minikube cluster

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/vars.sh
source ${DIR}/utils.sh

export TEMPLATES=${DIR}/../k8s/templates/dev
export CONSUL_APP_TAG=$(app_version)
export CONSUL_APP_IMAGE="consul-app:${CONSUL_APP_TAG}"
export CONSUL_NGINX_IMAGE="consul-nginx:${CONSUL_APP_TAG}"

export K8S_ENV="minikube"

#
# minikube specific utils
#

function connect-docker() {
  eval $(minikube docker-env)
}

function connect-kubectl() {
  kubectl config use-context minikube
}

function url() {
  echo http://`minikube ip`:${MINIKUBE_PORT}
}

#
# build
#

function build() {
  check-deployment-version
  connect-docker
  connect-gcloud
  gcloud docker -- pull eu.gcr.io/momentum-mxv/base
  build-images
}

function clean() {
  eval $(minikube docker-env)
  docker rm -f $(docker ps -a | grep Exited | awk '{print $1}') || true
  docker rm -f $(docker ps -a | grep Created | awk '{print $1}') || true
}

# NOTE - most of the functions here are defined in utils.sh

main "$@"