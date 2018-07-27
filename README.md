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

## Connecting to an admin console (if applicable)
## Connecting a client tool and running a sample command (if applicable)
## Modifying usernames and passwords
## Enabling ingress and installing TLS certs (if applicable)

# Backup and restore

Kong relies on the underlying datastore (Postgresql in this deployment) for
storing its configuration. You can use standard database tools to
clone/backup/restore your data.

# Image updates
## Updating application images, assuming patch/minor updates

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

The application can be deleted as mentioned in the [Installing] paragraph,
by running the following command:

```shell
make app/uninstall
```

## Orphaned resources after deletion

When the application is deleted the PVC (persistent volume claim) for the
database storage will stay behind orphaned. It can be deleted manually.
