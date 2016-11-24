MINIKUBE_VERSION=0.12.2
KUBECTL_VERSION=1.4.3

#
# utils
#

# ensure the download folder
.PHONY: ensure_folders
ensure_folders:
	mkdir -p .private

#
# install
#

# install the kubectl binary
.PHONY: kubectl.install
kubectl.install: ensure_folders
	cd .private && \
  curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERSION)/bin/darwin/amd64/kubectl && \
  chmod +x kubectl && \
  sudo mv kubectl /usr/local/bin/

# install the minikube binary
.PHONY: minikube.install
minikube.install: ensure_folders
	cd .private && \
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/v$(MINIKUBE_VERSION)/minikube-darwin-amd64 && \
  chmod +x minikube && \
  sudo mv minikube /usr/local/bin/

#
# docker-compose
#

# build the docker-compose images
.PHONY: compose.build
compose.build:
	bash scripts/compose.sh build

# initialize the postgres db
.PHONY: compose.initialize
compose.initialize:
	bash scripts/compose.sh initialize

# get a cli onto the docker-compose postgres
.PHONY: compose.postgres.cli
compose.postgres.cli:
	bash scripts/compose.sh postgres-cli

.PHONY: compose.app.cli
compose.app.cli:
	bash scripts/compose.sh app-cli

.PHONY: compose.app.assets
compose.app.assets:
	bash scripts/compose.sh app-assets

#
# gcloud
#

# point kubectl at the production gcloud k8s cluster
# note this needs to be run like this: eval $(make kubectl.gcloud)
.PHONY: gcloud.kubectl
gcloud.kubectl:
	bash scripts/gcloud.sh connect-kubectl

.PHONY: gcloud.info
gcloud.info:
	bash scripts/gcloud.sh info

.PHONY: gcloud.info.full
gcloud.info.full:
	bash scripts/gcloud.sh info 1

# build and tag the image for gcr
.PHONY: gcloud.build
gcloud.build:
	bash scripts/gcloud.sh build

# update the deployment with the new image
.PHONY: gcloud.deploy
gcloud.deploy:
	bash scripts/gcloud.sh deploy

# update the deployment configs
.PHONY: gcloud.update
gcloud.update:
	bash scripts/gcloud.sh update

# revert to the last deployment
.PHONY: gcloud.rollback
gcloud.rollback:
	bash scripts/gcloud.sh rollback

.PHONY: gcloud.namespace.create
gcloud.namespace.create:
	bash scripts/gcloud.sh create-namespace

# spin up postgres on gcloud
.PHONY: gcloud.postgres.create
gcloud.postgres.create:
	bash scripts/gcloud.sh create-postgres

# destroy the postgres resources (enforced to the local version)
.PHONY: gcloud.postgres.destroy
gcloud.postgres.destroy:
	bash scripts/gcloud.sh destroy-postgres

.PHONY: gcloud.postgres.cli
gcloud.postgres.cli:
	bash scripts/gcloud.sh postgres-cli

# spin up the consul app deployment
.PHONY: gcloud.app.create
gcloud.app.create:
	bash scripts/gcloud.sh create-app

# destroy the app resources (enforced to the local version)
.PHONY: gcloud.app.destroy
gcloud.app.destroy:
	bash scripts/gcloud.sh destroy-app

.PHONY: gcloud.app.cli
gcloud.app.cli:
	bash scripts/gcloud.sh app-cli

.PHONY: gcloud.app.exec
gcloud.app.exec:
	bash scripts/gcloud.sh app-exec

.PHONY: gcloud.cron.exec
gcloud.cron.exec:
	bash scripts/gcloud.sh cron-exec

.PHONY: gcloud.cron.logs
gcloud.cron.logs:
	bash scripts/gcloud.sh cron-logs

.PHONY: gcloud.worker.logs
gcloud.worker.logs:
	bash scripts/gcloud.sh worker-logs

#
# minikube
#

# point kubectl at the local minikube cluster
.PHONY: minikube.kubectl
minikube.kubectl:
	bash scripts/minikube.sh connect-kubectl

.PHONY: minikube.info
minikube.info:
	bash scripts/minikube.sh info

.PHONY: minikube.info.full
minikube.info.full:
	bash scripts/minikube.sh info 1

# ssh into the minikube VM
.PHONY: minikube.ssh
minikube.ssh:
	minikube ssh

# point docker at the minikube vm
.PHONY: minikube.docker
minikube.docker:
	@minikube docker-env

# print the URL to see the app running inside the minikube vm
.PHONY: minikube.url
minikube.url:
	@bash scripts/minikube.sh url

# rebuild the app inside the minikube vm
.PHONY: minikube.build
minikube.build:
	bash scripts/minikube.sh build

# update the deployment with the new image
.PHONY: minikube.deploy
minikube.deploy:
	bash scripts/minikube.sh deploy

# update the deployment configs
.PHONY: minikube.update
minikube.update:
	bash scripts/minikube.sh update
	
# revert to the last deployment
.PHONY: minikube.rollback
minikube.rollback:
	bash scripts/minikube.sh rollback
	
# remove exited containers inside the minikube vm
.PHONY: minikube.clean
minikube.clean:
	bash scripts/minikube.sh clean

.PHONY: minikube.namespace.create
minikube.namespace.create:
	bash scripts/minikube.sh create-namespace

# spin up postgres (enforced to the local version)
.PHONY: minikube.postgres.create
minikube.postgres.create:
	bash scripts/minikube.sh create-postgres

# destroy the postgres resources (enforced to the local version)
.PHONY: minikube.postgres.destroy
minikube.postgres.destroy:
	bash scripts/minikube.sh destroy-postgres

#kubectl run -i --tty busybox --image=busybox --restart=Never --rm -- sh
#psql -h 10.0.0.50 -U consul
.PHONY: minikube.postgres.cli
minikube.postgres.cli:
	bash scripts/minikube.sh postgres-cli

# spin up the consul app deployment
.PHONY: minikube.app.create
minikube.app.create:
	bash scripts/minikube.sh create-app

# destroy the app resources (enforced to the local version)
.PHONY: minikube.app.destroy
minikube.app.destroy:
	bash scripts/minikube.sh destroy-app

.PHONY: minikube.app.cli
minikube.app.cli:
	bash scripts/minikube.sh app-cli

.PHONY: minikube.app.exec
minikube.app.exec:
	bash scripts/minikube.sh app-exec

.PHONY: minikube.cron.logs
minikube.cron.logs:
	bash scripts/minikube.sh cron-logs

.PHONY: minikube.cron.exec
minikube.cron.exec:
	bash scripts/minikube.sh cron-exec

.PHONY: minikube.worker.logs
minikube.worker.logs:
	bash scripts/minikube.sh worker-logs
