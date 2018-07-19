# Overview

This repository contains the source of the Google Kubernetes Cloud
launcher app for Kong.

For now it will only hold a Kong-CE version.

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

# Marketplace Integration Requirements

Briefly, apps must support two modes of installation:
- **CLI**: via a Kubernetes client tool like kubectl or helm
- **Marketplace UI**: via the deployment container ("deployer") mechanism.

A few additional Marketplace requirements are described below.

## Application resource and controller

Apps must supply an Application resource conforming to the
[Kubernetes community proposal](https://github.com/kubernetes/community/pull/1629).
The proposal describes the Application resource, as well as a corresponding
controller that would be responsible for application-generic functionality such
as assigning owner references to application components.

**Temporary Note**: the public source repository associated with the proposal is
not yet available. In the interim, we have an equivalent CRD and controller in
the marketplace-k8s-app-tools repository. Expect changes once the public repo is
available.

## Deployer

Apps must supply a deployment container image ("deployer") which is used in
UI-based deployment. This image should extend from one of the base images
provided in the marketplace-k8s-app-tools repository.

# Kong identifiers

## Overall

- GCE project: `kong-206419`
- Partner id: `kong`
- Product id: `kong-ce`
- Partner name: `Kong Inc.`

## Container images

Container images will be pushed to the registry `gcr.io/kong-206419/` (this prefix is 
automatically derived from the local `gcloud` and `kubectl` configurations).

- `kong/kong-ce`
- `kong/kong-ce/postgres`