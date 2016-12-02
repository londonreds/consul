#!/bin/bash -e

# util functions and variables
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#
# helpers
#

# process a text file with env var substitution
function template() {
  local file="$1"

  if [[ ! -f "${file}" ]]; then
    >&2 echo "${file} does not exist"
    exit 1
  fi

  perl -p -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg; s/\$\{([^}]+)\}//eg' ${file}
}

# quit if the safety switch is on
function check_safety_switch() {
  if [ -n "${SAFETY_SWITCH_ON}" ]; then
    >&2 echo "disabled"
    exit 1
  fi
}

# point gcloud at the correct project
function connect-gcloud() {
  gcloud config set project momentum-mxv
}

# return the current git hash - used for image tags
function current_git_hash() {
  git rev-parse HEAD
}

# manual tagging
function app_version() {
  cat ${DIR}/../version
}

# get the name of the app pod
function app-podname() {
  kubectl get pod --namespace ${CONSUL_APP_NAMESPACE} | grep app | grep -v Terminating | awk '{print $1}' | head -n 1
}

function nginx-podname() {
  kubectl get pod --namespace ${CONSUL_APP_NAMESPACE} | grep nginx | grep -v Terminating | awk '{print $1}' | head -n 1
}

function cron-podname() {
  kubectl get pod --namespace ${CONSUL_APP_NAMESPACE} | grep cron | grep -v Terminating | awk '{print $1}' | head -n 1
}

function worker-podname() {
  kubectl get pod --namespace ${CONSUL_APP_NAMESPACE} | grep worker | grep -v Terminating | awk '{print $1}' | head -n 1
}

function gcr_image() {
  local SERVICENAME="$1"
  echo "${GCR_REGION}/${GCR_PROJECT}/${SERVICENAME}:${CONSUL_APP_TAG}"
}

# check that the local version is not the same as the deployed container version
function check-deployment-version() {
  connect-kubectl
  local apppod=$(app-podname)
  local appimage=$(kubectl describe po ${apppod} --namespace ${CONSUL_APP_NAMESPACE} | grep Image: | awk '{print $2}')
  local imageversion=$(echo $appimage | awk -F  ":" '/1/ {print $2}')

  echo "local version: ${CONSUL_APP_TAG}"
  echo "remote version: ${imageversion}"

  # this means the local version is the same as the deployed version
  if [[ "${imageversion}" == "${CONSUL_APP_TAG}" ]]; then
    echo >&2 "Please bump the version file"
    exit 1
  else
    echo "Current deployed version: ${imageversion}"
    echo "Building version ${CONSUL_APP_TAG}"
  fi
}

#
# deploy
#

# this builds the image and triggers a deployment update by changing the image
function deploy() {
  connect-kubectl
  echo "Deploying nginx: ${CONSUL_NGINX_IMAGE}"
  kubectl set image deployment/nginx *=${CONSUL_NGINX_IMAGE} --namespace ${CONSUL_APP_NAMESPACE}
  echo "Deploying app: ${CONSUL_APP_IMAGE}"
  kubectl set image deployment/app *=${CONSUL_APP_IMAGE} --namespace ${CONSUL_APP_NAMESPACE}
  echo "Deploying cron: ${CONSUL_APP_IMAGE}"
  kubectl set image deployment/cron *=${CONSUL_APP_IMAGE} --namespace ${CONSUL_APP_NAMESPACE}
  echo "Deploying worker: ${CONSUL_APP_IMAGE}"
  kubectl set image deployment/worker *=${CONSUL_APP_IMAGE} --namespace ${CONSUL_APP_NAMESPACE}
}

function rollback() {
  connect-kubectl
  kubectl rollout undo deployment/nginx --namespace ${CONSUL_APP_NAMESPACE}
  kubectl rollout undo deployment/app --namespace ${CONSUL_APP_NAMESPACE}
  kubectl rollout undo deployment/cron --namespace ${CONSUL_APP_NAMESPACE}
  kubectl rollout undo deployment/worker --namespace ${CONSUL_APP_NAMESPACE}
}

# this updates the pod configuration
function update() {
  connect-kubectl
  echo "Updating nginx deployment"
  template ${TEMPLATES}/nginx-deployment.json | kubectl apply -f -
  echo "Updating app deployment"
  template ${TEMPLATES}/app-deployment.json | kubectl apply -f -
  echo "Updating cron deployment"
  template ${TEMPLATES}/cron-deployment.json | kubectl apply -f -
  echo "Updating worker deployment"
  template ${TEMPLATES}/worker-deployment.json | kubectl apply -f -
}

#
# build
#

function build-images() {
  connect-docker
  docker build -f ${DIR}/../Dockerfile.app -t ${CONSUL_APP_IMAGE} ${DIR}/..
  docker build -f ${DIR}/../Dockerfile.nginx -t ${CONSUL_NGINX_IMAGE} ${DIR}/..
  echo "built ${CONSUL_APP_IMAGE}"
  echo "built ${CONSUL_NGINX_IMAGE}"
}

#
# namespace
#

function create-namespace() {
  check_safety_switch
  connect-kubectl
  template ${TEMPLATES}/namespace.json | kubectl create -f -
}

#
# postgres
#

function create-postgres() {
  check_safety_switch
  connect-kubectl
  template ${TEMPLATES}/postgres-master-pv.json | kubectl create -f -
  template ${TEMPLATES}/postgres-master-pvc.json | kubectl create -f -
  template ${TEMPLATES}/postgres-master-pod.json | kubectl create -f -
  template ${TEMPLATES}/postgres-master-service.json | kubectl create -f -
}

function destroy-postgres() {
  check_safety_switch
  connect-kubectl
  kubectl delete pod postgres-master --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete svc postgres --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete pv postgres-master-volume --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete pvc postgres-master-volume-claim --namespace ${CONSUL_APP_NAMESPACE} || true
}


function postgres-command() {
  connect-kubectl
  kubectl delete po postgres-cli --namespace ${CONSUL_APP_NAMESPACE} || true
  echo
  echo "running a connected postgres container"
  echo "wait a few seconds then press enter"
  echo "then paste the following command"
  echo
  echo $@
  echo
  kubectl run -i --tty --rm \
    --attach=true \
    --restart=Never \
    --quiet=true \
    --env="PGPASSWORD=${POSTGRES_SERVICE_PASSWORD}" \
    --image=${POSTGRES_DOCKER_IMAGE} \
    --leave-stdin-open=true \
    --namespace=${CONSUL_APP_NAMESPACE} \
    postgres-cli -- sh
}

function postgres-cli() {
  postgres-command "psql -h \${POSTGRES_SERVICE_HOST} -U consul"
}

#
# app
#

function create-app-deployments() {
  check_safety_switch
  connect-kubectl
  echo "creating app deployments"
  template ${TEMPLATES}/nginx-deployment.json | kubectl create -f -
  template ${TEMPLATES}/app-deployment.json | kubectl create -f -
  template ${TEMPLATES}/cron-deployment.json | kubectl create -f -
  template ${TEMPLATES}/worker-deployment.json | kubectl create -f -
}

function create-app-services() {
  check_safety_switch
  connect-kubectl
  echo "creating app services"
  template ${TEMPLATES}/nginx-service.json | kubectl create -f -
  template ${TEMPLATES}/app-service.json | kubectl create -f -
}

function create-app() {
  check_safety_switch
  build
  create-app-services
  echo "waiting for services to register"
  sleep 10
  create-app-deployments
}

function destroy-app-deployments() {
  check_safety_switch
  connect-kubectl
  kubectl delete deployment app --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete deployment nginx --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete deployment cron --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete deployment worker --namespace ${CONSUL_APP_NAMESPACE} || true
}

function destroy-app-services() {
  check_safety_switch
  connect-kubectl
  kubectl delete svc app --namespace ${CONSUL_APP_NAMESPACE} || true
  kubectl delete svc nginx --namespace ${CONSUL_APP_NAMESPACE} || true
}

function destroy-app() {
  destroy-app-deployments
  destroy-app-services
}

function app-command() {
  connect-kubectl
  kubectl delete po app-cli --namespace ${CONSUL_APP_NAMESPACE} || true
  local cmd="sleep 2 && echo \"\n\" && $@"
  echo "connecting to: ${CONSUL_APP_IMAGE}"
  kubectl run -i --tty --rm \
    --restart=Never \
    --quiet=true \
    --port=80 \
    --env="POSTGRES_SERVICE_USER=${POSTGRES_SERVICE_USER}" \
    --env="POSTGRES_SERVICE_PASSWORD=${POSTGRES_SERVICE_PASSWORD}" \
    --env="POSTGRES_SERVICE_DATABASE=${POSTGRES_SERVICE_DATABASE}" \
    --image=${CONSUL_APP_IMAGE} \
    --namespace=${CONSUL_APP_NAMESPACE} \
    app-cli -- sh -c "$cmd"
}

# this is different to app-command in that it execs into the already
# running app container and does not spawn a new one (like run does)
function app-exec() {
  connect-kubectl
  kubectl exec --namespace=${CONSUL_APP_NAMESPACE} -t -i `app-podname` -- bash
}

function cron-exec() {
  connect-kubectl
  kubectl exec --namespace=${CONSUL_APP_NAMESPACE} -t -i `cron-podname` -- bash
}

function cron-logs() {
  connect-kubectl
  kubectl logs --namespace=${CONSUL_APP_NAMESPACE} `cron-podname`
}

function worker-logs() {
  connect-kubectl
  kubectl logs --namespace=${CONSUL_APP_NAMESPACE} `worker-podname` | grep -v "Delayed::Backend::ActiveRecord::Job Load"
}

function app-cli() {
  app-command bash
}

function info_title() {
  echo
  echo "--------------------------------------------"
  echo "$@"
  echo "--------------------------------------------"
}

function info_command() {
  echo "$ $@"
  echo "--------------------------------------------"
  echo
  eval "$@"
}

function info() {
  connect-kubectl

  if [ -n "$1" ]; then
    info_title "describe app pod"
    info_command kubectl describe po $(app-podname) --namespace=${CONSUL_APP_NAMESPACE}
    
    info_title "describe nginx pod"
    info_command kubectl describe po $(nginx-podname) --namespace=${CONSUL_APP_NAMESPACE}

    info_title "describe app deployment"
    info_command kubectl describe deployment app --namespace=${CONSUL_APP_NAMESPACE} || true
    
    info_title  "describe nginx deployment"
    info_command kubectl describe deployment nginx --namespace=${CONSUL_APP_NAMESPACE} || true
  fi

  info_title "ingress"
  info_command kubectl get ingress --namespace=${CONSUL_APP_NAMESPACE}

  info_title  "persistent volumes"
  info_command kubectl get pv --namespace=${CONSUL_APP_NAMESPACE}
  
  info_title  "persistent volume claims"
  info_command kubectl get pvc --namespace=${CONSUL_APP_NAMESPACE}
  
  info_title  "services"
  info_command kubectl get svc --namespace=${CONSUL_APP_NAMESPACE}

  info_title "deployments"
  info_command kubectl get deployments --namespace=${CONSUL_APP_NAMESPACE}

  info_title "pods"
  info_command kubectl get po --namespace=${CONSUL_APP_NAMESPACE}
}

function usage() {
cat <<EOF
Usage:
  info                 print cluster resources
  connect-kubectl      point kubectl at the ${K8S_ENV} k8s cluster
  build                send the local code into the ${K8S_ENV} cluster
  deploy               trigger a k8s deployment rollout with the new code
  update               update the k8s deployment configuration ready for the next deploy
  rollback             undo the last deployment rollout
  url                  print the url to view the app in a browser
  create-namespace     create the consul app namespace
  create-postgres      create the postgres resources
  destroy-postgres     destroy the postgres resources
  create-app           create the app resources
  destroy-app          destroy the app resources
  app-cli              get a bash cli inside a new, connected app container
  app-exec             get a bash cli inside the existing, running app container
  cron-exec            get a bash cli inside the existing, running cron container
  postgres-cli         get a psql cli connected to Postgres
  clean                remove exited containers
  status               show current resources
  cron-logs            get the logs from the cron container
  worker-logs          get the logs from the worker container
  help                 display this message
EOF
  exit 1
}

function main() {
  case "$1" in
  connect-kubectl)  shift; connect-kubectl $@;;
  url)              shift; url $@;;
  build)            shift; build $@;;
  deploy)           shift; deploy $@;;
  update)           shift; update $@;;
  rollback)         shift; rollback $@;;
  create-namespace) shift; create-namespace $@;;
  create-postgres)  shift; create-postgres $@;;
  destroy-postgres) shift; destroy-postgres $@;;
  create-app)       shift; create-app $@;;
  destroy-app)      shift; destroy-app $@;;
  app-cli)          shift; app-cli $@;;
  app-exec)         shift; app-exec $@;;
  cron-exec)        shift; cron-exec $@;;
  postgres-cli)     shift; postgres-cli $@;;
  initialize)       shift; initialize $@;;
  clean)            shift; clean $@;;
  info)             shift; info $@;;
  cron-logs)        shift; cron-logs $@;;
  worker-logs)      shift; worker-logs $@;;
  template)         shift; template $@;;
  *)                usage $@;;
  esac
}
