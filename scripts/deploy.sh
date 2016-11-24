#!/bin/bash -e

set -e

#
# deploy the stack the google container cluster we are running
#
# we will manually deploy from a developers laptop (for expediency)
# we should replace this with CI that is triggered by merging to master
# (or chatops or whatevs)
#
# there are 2 types of deploy - staging + production
#
# staging involves:
#  * building docker image
#  * pushing to google cloud
#  * updating staging pods with new image
#
# production involves:
#  * updating production pods with a staging image
#
# what image a.k.a. version of the code we are currently running is described
# by the k8s manifests in the k8s folder
#
# these manifest remain part of source control
# after each deploy a commit is made with the change to the k8s manifests
# this makes it easy to roll back the deployment
# (because we have the previous config in git and the previous images on gcr)
#
# the workflow is to use a deploy script that will:
#
#  * check we are on latest origin/master
#  * make a hash of the local content
#  * gcloud docker build an image for the app - tag it with the hash
#  * gcloud docker push the image to gcr
#  * overwrite the k8s manifests for staging
#
# the user will then examine the kube configs (using git diff or whatever)
# then they will use a kubectl command to apply these updates to the cluster
#
# deploy to production is a case of applying the staging image tag to the production pod

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/vars.sh
