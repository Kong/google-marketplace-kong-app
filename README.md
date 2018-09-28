# Overview

This repository contains the source and instructions for the Google Cloud
Platform Marketplace launcher app for
[deploying Kong on Google Kubernetes Engine(GKE)](https://console.cloud.google.com/marketplace/details/kong/kong),
or for deploying Kong on a non-GKE Kubernetes cluster.

This repository currently installs Kong only, and not Kong Enterprise. To
install Kong Enterprise on Kubernetes, see https://docs.konghq.com/install/kubernetes/

There are 2 parts to this README:

1. [Install and use Kong on Google Kubernetes Engine via the Google Cloud Platform Marketplace](#basic-usage)
2. [Use this repo to build your own images and deployments on non-GKE Kubernetes cluster](#building-your-own)

# Basic usage

<!-- Use the Google Marketplace to get your Kong installation installed.
Once that is successful, you can use the below command line examples to
perform additional tasks. -->

This sequence assumes you are using the Google Cloud Platform browser interface.

1. On https://console.cloud.google.com/marketplace/details/kong/kong click "Configure"
1. Follow the prompts to select an Organization and Project (as allowed by your
  Google Cloud Platform permissions)
1. Follow the prompts to select a cluster zone, create or select a cluster,
choose a namespace, and name your app instance, then click "Deploy"
1. Kong and its dependency Postgres will be deployed - this may take a few minutes
1. Switch to the `[app-instance-name]-kong-proxy-svc` service and visit that
service's external endpoint - you should see
`"message": "no route and no API found with those values"`, which means that
Kong is running, but that it has not been configured to proxy API requests

## Connecting to the Admin API to configure Kong

To configure Kong, you must connect to Kong's [Admin API](https://docs.konghq.com/latest/admin-api/).
A Kubernetes Service has been created for Kong's Admin API, but that service
has been defined as `ClusterIP`, and is not accessible from outside
the Kubernetes cluster.

Thus, to configure Kong, you can either expose the Kong's Admin API to make
it accessible from outside the Kubernetes cluster, or you can configure
Kong from within the cluster.

### Connect to Admin API from within the cluster

To access the Admin API from within the cluster, eg. through the Kong node itself:

```shell
export NAME=app-instance-name
export NAMESPACE=your-namespace
export KONG_NODE=$(kubectl get pods --namespace=$NAMESPACE \
   --selector=app.kubernetes.io/component=kong-node,app.kubernetes.io/name=$NAME \
   -o go-template='{{(index .items 0).metadata.name}}')

kubectl exec -it $KONG_NODE curl http://localhost:8001/
```

### Connect to Admin API from outside the cluster

You can make Kong's Admin API accessible by patching the service to a
`LoadBalancer` type instead of a `ClusterIP`.

**WARNING**: Exposing the Admin API like this makes your Kong instance
available to anyone! Be sure to revert the change, or [implement access control](https://docs.konghq.com/0.14.x/secure-admin-api/), or delete your
application or cluster when you are done experimenting!

#### Expose Admin API via browser UI

In the Google Cloud Platform browser UI, you can change Kong's Admin API from
an internal-only ClusterIP service to an externally-accessible LoadBalancer service:

1. Switch to the `[app-instance-name]-kong-admin-svc` service
1. Click "Edit" at the top of the screen
1. Near the end of the YAML, change `type: ClusterIP` to `type: LoadBalancer`
and click "Save" - this may take a few minutes (and you may need to refresh the page)
1. Once your change has been applied, the `[app-instance-name]-kong-admin-svc`
service will show an external endpoint - visit that address, and you should see
the normal output of the [Admin API `/` endpoint](https://docs.konghq.com/latest/admin-api/#information-routes)

#### Expose Admin API via terminal

Or to do this via the terminal:

```shell
export NAME=app-instance-name
export NAMESPACE=your-namespace

kubectl patch svc $NAME-kong-admin-svc \
  --namespace $NAMESPACE \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

The LoadBalancer may take a few minutes to start. After that you can get access
like this:

```shell
export NAME=app-instance-name
export NAMESPACE=your-namespace

export ADMIN_IP=$(kubectl get \
  --namespace=$NAMESPACE svc/$NAME-kong-admin-svc \
  -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}')
export ADMIN_HTTP=$ADMIN_IP:8001
export ADMIN_HTTPS=$ADMIN_IP:8444

curl http://$ADMIN_HTTP/
```

Now that you have access to both Kong's proxy ports and to Kong's Admin API
ports, you can follow the [Kong quick start guide](https://docs.konghq.com/latest/getting-started/configuring-a-service/).

## Scaling

When needing to scale Kong, the only component to scale is the Kong node.

For example:

```shell
export NAME=your-installation-name
export NAMESPACE=your-namespace

kubectl scale deployment $NAME-kong \
  --namespace=$NAMESPACE --replicas=5
```

## Backup and restore

Kong relies on the underlying datastore (Postgres in this deployment) for
storing its configuration. You can use standard database tools to
clone/backup/restore your data.

## Deletion

When the application is deleted the PVC (persistent volume claim) for the
database storage will stay behind orphaned. It can be deleted manually.

## Image updates

To update the Kong version running in the application, you can update
the image used to run it.

**WARNING**: This assumes only patch updates (eg. 0.13.0 to 0.13.1), since
other updates (eg. 0.13.x to 0.14.x) are not compatible and require migrations.
See also the information at [overriding context values](#overriding-context-values).

```shell
export NAME=your-installation-name
export NAMESPACE=your-namespace

# first check the current Kong version running
export KONG_NODE=$(kubectl get pods --namespace=$NAMESPACE \
   --selector=app.kubernetes.io/component=kong-node,app.kubernetes.io/name=$NAME \
   -o go-template='{{(index .items 0).metadata.name}}')
kubectl exec -it $KONG_NODE curl http://localhost:8001/ | jq '.version'

# get the image name
export IMAGE_NAME=$(kubectl get deployment \
  --namespace=$NAMESPACE $NAME-kong \
  -o go-template='{{(index .spec.template.spec.containers 0).image}}' \
  | cut -d':' -f1)

# update the image to the new version
export NEW_TAG=0.14.1
kubectl set image --namespace=$NAMESPACE deployments/$NAME-kong kong-node=$IMAGE_NAME:$NEW_TAG

# after the new images have been deployed and the old ones have been removed,
# check the version again. The node may have changed, so fetch that first.
export KONG_NODE=$(kubectl get pods --namespace=$NAMESPACE \
   --selector=app.kubernetes.io/component=kong-node,app.kubernetes.io/name=$NAME \
   -o go-template='{{(index .items 0).metadata.name}}')
kubectl exec -it $KONG_NODE curl http://localhost:8001/ | jq '.version'
```

# Building your own

This section explains how to use this repository to build and deploy Kong
manually using the makefiles.

The repo utilizes the [marketplace-k8s-app-tools](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools)
repository, which contains utilities for the Marketplace.
The repository is submoduled under `/vendor/marketplace-tools`.

## Updating git submodules

You can run the following commands to make sure submodules
are populated with proper code.

```shell
git submodule sync --recursive
git submodule update --recursive --init --force
```

## Setting up your cluster and environment

See [Getting Started](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools/blob/master/README.md#getting-started)

## Installing

Run the following commands from within the `kong` folder.

Do a one time setup for application CRD:

```shell
make crd/install
```

Build and install Kong onto your cluster:

```shell
make app/install
```

To delete the installation, run:

```shell
make app/uninstall
```

## Overriding context values

By default `make` derives docker registry and k8s namespace
from your local configurations of `gcloud` and `kubectl`.

You can see these values using

```shell
kubectl config view
```

If you want to use values that differ from the local context of `gcloud` and `kubectl`,
you can override them by exporting the appropriate environment variables:

```shell
export REGISTRY=gcr.io/your-registry
export NAMESPACE=your-namespace
export NAME=your-installation-name     #default "kong-1"
export TRACK=your-track                #default "0.14"
export TRACK_MINOR=minor-version       #default "1"
```

The `TRACK` is the application track (sequence of compatible releases), eg. `TRACK=0.14`.
The `TRACK_MINOR` is the minor version within the track version, eg. `TRACK_MINOR=1`.
The combination of `TRACK`.`TRACK_MINOR` should be a valid Kong version number, eg. `0.14.1`.

In the above example rolling out the app at track 0.14, will install Kong 0.14.1

### Versioning notes

- Building is assumed in chronological order, as the build version will always be tagged
  as the track version. Eg. after building `0.14.0`, the track `0.14` will point to `0.14.0`.
  So when building `0.14.1` and then `0.14.0` then the track will point to `0.14.0` and installs
  will not get the latest version.
- Since within a track there is compatibility, the images for "tester", "deployer", and "postgres" will
  only be tagged by the track version (Eg. `0.14`). Only the Kong image will be tagged by both
  the track as well as the minor version (Eg. `0.14` and `0.14.1`.
