# devops

## local development

Presently everything is tested with OSX El Captain - other platforms might work.

To develop the app locally you need to first install:

 * [docker](https://docs.docker.com/engine/installation/mac/)

Install `docker for Mac` not the Docker toolbox.

Then clone this repository somewhere on your system:

```bash
$ git clone https://github.com/PeoplesMomentum/consul
$ cd consul
```

### docker-compose

The first time you run the system - the database needs initializing:

```bash
$ make compose.initialize
```

Then you can bring up the stack:

```bash
$ docker-compose up
```

You can then visit the site in a browser [http://localhost:3000](http://localhost:3000)

The initial setup of the database will seed it with example data - you can use the following details to login:

```
user: verified@consul.dev
pass: 12345678
```

The app container will create a `.private` folder in which the Postgres data lives - if you want to reset the database, stop the stack, delete this folder and re-run `make compose.initialize` then re-run `docker-compose up`.

### docker-compose.yml

This file controls the stack and you can change things like entrypoint, volume mounts and env variables here.

### rebuilding assets

If you change any of the assets - to prepare them for a production deployment you must run the following command (whilst the `docker-compose up` stack is running):

```bash
$ make compose.app.assets
```

This will update the `public/assets` folder with the new content.  You should git commit these results (i.e. the build artifacts live in source control so the Docker build deploy can consume them).

### connecting to postgres

To get a cli onto the Postgres container (useful to poke around the database):

```bash
$ make compose.postgres.cli
$ \list
$ \connect consul
$ \dt
$ \q
```

## local k8s

You can run a version of the production stack inside kubernetes on your local machine - this is useful to debug and develop in the environment the app is actually running (although mostly development can be done in the more flexible docker-compose setup).

### install

To run the application locally using Kubernetes - we need to install:

 * [virtualbox](https://www.virtualbox.org/wiki/Downloads) (enables VMs to be run)
 * [minikube](https://github.com/kubernetes/minikube) (runs a local development k8s cluster)
 * [kubectl](https://coreos.com/kubernetes/docs/latest/configure-kubectl.html) (the k8s cli)


Here is the [direct link](http://download.virtualbox.org/virtualbox/5.1.8/VirtualBox-5.1.8-111374-OSX.dmg) to the Virtualbox DMG

NOTE: if can skip kubectl if you already have it installed (although check `kubectl version`)

```bash
$ make install.minikube
$ make install.kubectl
```

### start the cluster

Then we can bring up a local single node k8s cluster:

```bash
$ minikube start
$ minikube status
```

Every time we want to speak to our local cluster - we need to point kubectl at it:

```bash
$ make kubectl.minikube
```

Then we can use `kubectl` normally:

```
$ kubectl get nodes
```

To can see the status of the stack (useful to see if stuff is running or not):

```bash
$ make minikube.info
```

### initial setup

First - create the consulapp namespace:

```bash
$ make minikube.namespace.create
```

Then - we run the postgres server (and wait for it to boot up the first time):

```bash
$ make minikube.postgres.create
$ sleep 20
```

Then initialize the database (once the postgres pod is running - this will take a while the first time).

```bash
$ make minikube.initialize
```

Then deploy the app resources:

```bash
$ make minikube.app.create
```

Then display the URL to open in your browser:

```bash
$ make minikube.url
```

### operation

Once you have run the initial setup - you can destroy the k8s resources like so:

```bash
$ make minikube.destroy
```

Then - to re-start all the services and connect to it in a browser:

```bash
$ make minikube.create
$ make minikube.url
```

### notes

To use the same Docker as minikube (useful to quickly build images etc):

```bash
$ eval $(minikube docker-env)
```

To SSH onto the minikube VM:

```bash
$ make minikube.ssh
```

The postgres data lives in `/data/postgres-master-data` - to reset the database, first destroy the stack then:

```bash
$ minikube ssh
$ sudo rm -rf /data/postgres-master-data
$ exit
```

Then re-initialize the cluster and the database is reset.

## gke k8s

This following assumes you have been added to the gcloud `momentum-mxv` project and have the [gcloud cli](https://cloud.google.com/sdk/) installed and have done:

```bash
$ gcloud auth application-default login
$ gcloud config set project momentum-mxv
```
We are running the production cluster on [GKE](https://cloud.google.com/container-engine/) in `europe-west1-c`

```bash
$ gcloud container clusters list
```

### operation

To release new code into the production k8s cluster:

First - bump the version file:

```bash
$ vi version
$ git add vesion && git commit -m "1.0.15" && git push
```

The version number is used to tag the Docker image with GCE.

Next - we build and push the image:

```bash
$ make gcloud.build
```

Once the images have been pushed - we trigger a k8s deploymment rollout with the new image:

```bash
$ make gcloud.deploy
```

### initial setup

NOTE - this is done only once and should not need doing again.

The following is a log of the initial setup done on GCloud:

```bash
# create the namespaces
$ make gcloud.namespace.create
# spin up postgres and claim the persistent volume
$ make gcloud.postgres.create
# build/push the app image
$ make gcloud.build
# get a CLI on a connected app image
# (this might take a short while to pull the image)
$ make gcloud.app.cli
# initialize the database with the rake task
$ bin/rake db:setup
$ exit
# create the ingress (wait for the LoadBalancer Ingress to show up)
$ bash scripts/ingress.sh setup
# deploy kube-lego
$ bash scripts/ingress.sh setup
# deploy the application containers
$ make gcloud.app.create
# deploy the application ingress
$ bash scripts/ingress.sh app
```

#### deploy new code

First bump the version then git commit.

```bash
$ make gcloud.build
$ make gcloud.deploy
```

#### postgres master block device

The persistent volume used for the postgres master:

```bash
$ gcloud compute disks create --size=200GB --zone=europe-west1-c postgres-master-data
```

To get a list of the disks:

```bash
$ gcloud compute disks list
```

#### rebuilding the base image

If you change anything in the `Gemfile` you must:

```bash
$ docker build -t eu.gcr.io/momentum-mxv/base -f Dockerfile.base .
$ gcloud docker -- push eu.gcr.io/momentum-mxv/base
```

#### scale the app

To change the number of rails pods we are running - open `k8s/templates/prod/app-deployment.json`

Change `spec.replicas` to reflect how many rails apps we want.

Change `spec.strategy.rollingUpdate.maxUnavailable` to be less than this.

Then update the deployment definition:

```bash
$ make gcloud.app.update
```

#### get a postgres CLI

Because of an un-yet diagnosed issue - we can't spawn a postgres cli directly - run this command and it'll tell you what to do:

```bash
$ make gcloud.postgres.cli
```

#### run manual Rake tasks

To run a rake task we need a terminal inside the app container so we have the code and it needs to be connected to Postgres.

To get such a CLI:

```bash
$ make gcloud.app.cli
$ bin/rake tools:helloworld
```

#### run cron Rake tasks

To run tasks using cron - we edit the `cron/crontab` file.

Each rake task we invoke using the `/app/rake.sh` script (which re-directs output to stdout)

Here is the example `crontab`:

```
* * * * * /app/rake.sh tools:helloworld
```

Edit this file and do a build then deploy.  The new crontab will be in operation.


