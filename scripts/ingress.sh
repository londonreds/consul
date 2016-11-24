#!/bin/bash -e

set -e

#
# scripts that help deploy the app to the local minikube cluster

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/vars.sh
source ${DIR}/utils.sh

export TEMPLATES=${DIR}/../k8s/templates
export CONSUL_APP_TAG=$(app_version)
export CONSUL_APP_IMAGE=$(gcr_image app)
export CONSUL_NGINX_IMAGE=$(gcr_image nginx)

export K8S_ENV="gcloud"

# a safety switch for the live k8s cluster
export SAFETY_SWITCH_ON=1

check_safety_switch

function connect-kubectl() {
  gcloud container clusters get-credentials consul-cluster --zone europe-west1-c --project momentum-mxv  
}

if [ "$1" == "setup" ]; then
  connect-kubectl
  template ${TEMPLATES}/ingress/lego/00-namespace.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/nginx/00-namespace.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/nginx/default-deployment.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/nginx/default-service.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/nginx/configmap.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/nginx/service.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/nginx/deployment.yaml | kubectl create -f -

  echo "nginx ingress load balancer created - wait for the ip"

  watch kubectl describe svc nginx --namespace nginx-ingress
elif [ "$1" == "lego" ]; then
  connect-kubectl
  template ${TEMPLATES}/ingress/lego/configmap.yaml | kubectl create -f -
  template ${TEMPLATES}/ingress/lego/deployment.yaml | kubectl create -f -
  
  echo "kube-lego created"
elif [ "$1" == "app" ]; then
  connect-kubectl
  template ${TEMPLATES}/prod/ingress-tls.yaml | kubectl create -f -

  echo "HTTP ingress created: http://${CONSUL_APP_DOMAIN}"
  echo "HTTPS ingress created: https://${CONSUL_APP_DOMAIN}"
else
  >&2 echo "unknown command $1"
  exit 1
fi


