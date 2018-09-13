# TRACK is the published tag, so the tag for the currect track, this should be a Kong major version
# TRACK_MINOR is the exact minor version to publish for the track
# so the below uses Kong CE 0.14.1 and sets that as the version for track 0.14
TRACK ?= 0.14
TRACK_MINOR ?= 1
NAME ?= kong-1
# NAMESPACE and REGISTRY are auto collected from the gcloud/kubectl
# configuration if not provided

# changing TAG triggers a rebuild, which also must occur on minor versions
TAG = $(TRACK).$(TRACK_MINOR)

# Defines shared common properties
# Macros:
#   print_target
#   print_notice
#   print_error
# Value for:
#   MARKETPLACE_TOOLS_PATH
# Targets:
#   clean
include ../vendor/marketplace-tools/common.Makefile

# crd.Makefile provides targets to install Application CRD
# (k8s Custom Resource Definition).
# Provides make targets:
#   crd/install
#   crd/uninstall
include ../vendor/marketplace-tools/crd.Makefile

# gcloud.Makefile provides default values derived from local
# gcloud and kubectl environments.
#   REGISTRY
#   NAMESPACE
include ../vendor/marketplace-tools/gcloud.Makefile

# marketplace.Makefile provides targets to build the base
# deployer images locally.
# Provides make targets:
#   .build/marketplace/deployer/envsubst
#   .build/marketplace/deployer/helm
#   .build/marketplace/delete_deprecated
include ../vendor/marketplace-tools/marketplace.Makefile

# Class of targets that track variables for being defined
# and trigger rebuilds on changes of their values.
# Targets:
#   .build/var/VARNAME
include ../vendor/marketplace-tools/var.Makefile

# app.Makefile provides the main targets for installing the
# application.
# Macros:
#   name_parameter       --> name from APP_PARAMETERS
#   namespace_parameter  --> namespace from APP_PARAMETERS
#   combined_parameters  --> APP_* + APP_TEST_* parameters combined
# Targets:
#   app/build         (extensible)
#   app/install       (extensible)
#   app/install-test  (extensible)
#   app/uninstall
#   app/verify
#   app/watch
# It requires several APP_* variables defined as followed.
include ../vendor/marketplace-tools/app.Makefile

$(info ---- TRACK = $(TRACK))
$(info ---- TRACK_MINOR = $(TRACK_MINOR)     --- Kong CE $(TAG))

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/kong/kong-ce/deployer:$(TRACK)
APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)", \
  "imageKongCE": "$(REGISTRY)/kong/kong-ce:$(TRACK)", \
  "imagePostgres": "$(REGISTRY)/kong/kong-ce/postgres:$(TRACK)" \
}
TESTER_IMAGE ?= $(REGISTRY)/kong/kong-ce/tester:$(TRACK)
APP_TEST_PARAMETERS ?= { \
  "imageTester": "$(TESTER_IMAGE)" \
}


# Extend the target as defined in app.Makefile to
# include real dependencies.
app/build:: .build/kong-ce/deployer \
            .build/kong-ce/postgres \
            .build/kong-ce/tester \
            .build/kong-ce/kong-ce


.build/kong-ce: | .build
	mkdir -p "$@"

.build/kong-ce/deployer: apptest/deployer/* \
                         apptest/deployer/manifest/* \
                         deployer/* \
                         manifest/* \
                         schema.yaml \
                         .build/marketplace/deployer/envsubst \
                         .build/var/APP_DEPLOYER_IMAGE \
                         .build/var/REGISTRY \
                         .build/var/TAG \
                         | .build/kong-ce
	$(call print_target, $@)
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/kong/kong-ce" \
	    --build-arg TRACK="$(TRACK)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"

# build the tester image
.build/kong-ce/tester:
	$(call print_target, $@)
	docker pull cosmintitei/bash-curl
	docker tag cosmintitei/bash-curl "$(TESTER_IMAGE)"
	docker push "$(TESTER_IMAGE)"
	@touch "$@"

# Simulate building of primary app image. Actually just copying public Kong CE
# image to local registry. Publish both as the track version (major version), and with the patch tag
.build/kong-ce/kong-ce: .build/var/REGISTRY \
                        .build/var/TAG \
                        | .build/kong-ce
	$(call print_target, $@)
	docker pull "kong:$(TAG)"
	docker tag "kong:$(TAG)" "$(REGISTRY)/kong/kong-ce:$(TAG)"
	docker tag "kong:$(TAG)" "$(REGISTRY)/kong/kong-ce:$(TRACK)"
	docker push "$(REGISTRY)/kong/kong-ce:$(TAG)"
	docker push "$(REGISTRY)/kong/kong-ce:$(TRACK)"
	@touch "$@"

# Relocate public postgres image to $REGISTRY.
.build/kong-ce/postgres: .build/var/REGISTRY \
                         .build/var/TAG \
                         | .build/kong-ce
	$(call print_target, $@)
	gcloud docker -- pull launcher.gcr.io/google/postgresql9:9.6
	docker tag launcher.gcr.io/google/postgresql9:9.6 "$(REGISTRY)/kong/kong-ce/postgres:$(TRACK)"
	docker push "$(REGISTRY)/kong/kong-ce/postgres:$(TRACK)"
	@touch "$@"

