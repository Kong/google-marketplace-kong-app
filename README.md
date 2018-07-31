# Overview

This repository contains the source of the Google Kubernetes Cloud
launcher app for Kong.

For now it will only hold a Kong-CE version (Community Edition).

The repo utilizes the [marketplace-k8s-app-tools](https://github.com/GoogleCloudPlatform/marketplace-k8s-app-tools)
repository, which contains utilities for the Marketplace.
The repository is submoduled under `/vendor/marketplace-tools`.

# Getting started

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

Run the following commands from within `kong-ce` folder.

Do a one time setup for application CRD:

```shell
make crd/install
```

Build and install Kong-CE onto your cluster:

```shell
make app/install
```

This will build the containers and install the application. You can
watch the kubernetes resources being created directly from your CLI
by running:

```shell
make app/watch
```

To delete the installation, run:

```shell
make app/uninstall
```

## Overriding context values (Optional)

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
export TAG=your-tag                    #default "latest"
```

The `TAG` should be a valid Kong CE version number, eg. `TAG=0.14.0`

# Basic usage

## Connecting to the Admin API to configure Kong

The Admin API is not exposed by default. A Service has been created for it,
but defined as `ClusterIP` (and hence not accessible from outside the K8s
cluster).

So to configure Kong you can either open it up, or configure Kong from within the
cluster.

To access it from within the cluster, eg. through the Kong node itself:

```shell
export NAME=your-installation-name
export NAMESPACE=your-namespace
export KONG_NODE=$(kubectl get pods --namespace=$NAMESPACE \
   --selector=app.kubernetes.io/component=kong-ce-node,app.kubernetes.io/name=$NAME \
   -o go-template='{{(index .items 0).metadata.name}}')

kubectl exec -it $KONG_NODE curl http://localhost:8001
```

Alternatively you can open up the admin port by patching the Service to a
LoadBalancer type instead of a ClusterIP:

**WARNING**: Exposing the Admin API like this exposes it to everybody! So make
sure to revert the change!

```shell
export NAME=your-installation-name
export NAMESPACE=your-namespace

kubectl patch svc $NAME-kong-ce-admin-svc \
  --namespace $NAMESPACE \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

The LoadBalancer may take a few minutes to start. After that you can get access
like this:

```shell
export NAME=your-installation-name
export NAMESPACE=your-namespace

export ADMIN_IP=$(kubectl get \
  --namespace=$NAMESPACE svc/$NAME-kong-ce-admin-svc \
  -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}')
export ADMIN_HTTP=$ADMIN_IP:8001
export ADMIN_HTTPS=$ADMIN_IP:8444

curl http://$ADMIN_HTTP/
```

Since there now is access to the Kong configuration, you can follow the
[Kong quick start guide](https://docs.konghq.com/latest/getting-started/quickstart/)
from here. Just invoke the `curl` commands as described above.

# Backup and restore

Kong relies on the underlying datastore (Postgresql in this deployment) for
storing its configuration. You can use standard database tools to
clone/backup/restore your data.

# Image updates

To update the Kong CE version running in the application, you can update
the image used to run it.

**WARNING**: This assumes only patch updates (eg. 0.13.0 to 0.13.1), since
minor updates (eg. 0.13.x to 0.14.x) are not compatible and require migrations.

```shell
export NEW_TAG=0.14.1
export NAME=your-installation-name
export NAMESPACE=your-namespace
export IMAGE_NAME=$(kubectl get deployment \
  --namespace=$NAMESPACE $NAME-kong-ce \
  -o go-template='{{(index .spec.template.spec.containers 0).image}}' \
  | cut -d':' -f1)

kubectl set image --namespace=$NAMESPACE deployments/$NAME-kong-ce kong-ce-node=$IMAGE_NAME:$NEW_TAG
```

# Scaling

When needing to scale the application, the only component to scale is the
Kong node.

For example:

```shell
export NAME=your-installation-name
export NAMESPACE=your-namespace

kubectl scale deployment $NAME-kong-ce \
  --namespace=$NAMESPACE --replicas=5
```

# Deletion

The application can be deleted as mentioned in the [Installing paragraph](#installing),
by running the following command:

```shell
make app/uninstall
```

## Orphaned resources after deletion

When the application is deleted the PVC (persistent volume claim) for the
database storage will stay behind orphaned. It can be deleted manually.
