TAG ?= latest

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

# ubbagent is the metering agent.
# ubbagent.Makefile provides ".build/ubbagent/ubbagent"
# target to build the ubbagent image locally.
#include ../vendor/marketplace-tools/ubbagent.Makefile     removed, not used

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

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/kong/kong-ce/deployer:$(TAG)
NAME ?= kong-ce
APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)", \
  "imageKongCE": "$(REGISTRY)/kong/kong-ce:$(TAG)", \
  "imagePostgres": "$(REGISTRY)/kong/kong-ce/postgres:$(TAG)" \
}
#APP_PARAMETERS ?= { \
#  "name": "$(NAME)", \
#  "namespace": "$(NAMESPACE)", \
#  "imageWordpress": "$(REGISTRY)/example/wordpress:$(TAG)", \
#  "imageInit": "$(REGISTRY)/example/wordpress/init:$(TAG)", \    removed, not used
#  "imageMysql": "$(REGISTRY)/example/wordpress/mysql:$(TAG)", \
#  "imageUbbagent": "$(REGISTRY)/example/wordpress/ubbagent:$(TAG)", \   removed, not used
#  "reportingSecret": "$(NAME)-reporting-secret" \          removed, not used
#}
TESTER_IMAGE ?= $(REGISTRY)/kong/kong-ce/tester:$(TAG)
APP_TEST_PARAMETERS ?= { \
  "imageTester": "$(TESTER_IMAGE)" \
}

# Extend the target as defined in app.Makefile to
# include real dependencies.
app/build:: .build/kong-ce/deployer \
            .build/kong-ce/postgres \
            .build/kong-ce/tester \
            .build/kong-ce/kong-ce
#app/build:: .build/wordpress/deployer \
#            .build/wordpress/init \        removed, not used
#            .build/wordpress/mysql \
#            .build/wordpress/tester \
#            .build/wordpress/ubbagent \    removed, not used
#            .build/wordpress/wordpress


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
	    --build-arg TAG="$(TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


# disable this one for now, unknown what image this is: cosmintitei/bash-curl
.build/kong-ce/tester:
	$(call print_target, $@)
	#docker pull cosmintitei/bash-curl
	#docker tag cosmintitei/bash-curl "$(TESTER_IMAGE)"
	#docker push "$(TESTER_IMAGE)"
	@touch "$@"

# Simulate building of primary app image. Actually just copying public Kong CE
# image to local registry.
.build/kong-ce/kong-ce: .build/var/REGISTRY \
                        .build/var/TAG \
                        | .build/kong-ce
	$(call print_target, $@)
	docker pull "kong:$(TAG)"
	docker tag "kong:$(TAG)" "$(REGISTRY)/kong/kong-ce:$(TAG)"
	docker push "$(REGISTRY)/kong/kong-ce:$(TAG)"
	@touch "$@"

# Build secondary app image.
#.build/wordpress/init: init/* \                             not using initContainers
#                       .build/var/REGISTRY \
#                       .build/var/TAG \
#                       | .build/wordpress
#	$(call print_target, $@)
#	cd init \
#	&& docker build --tag "$(REGISTRY)/example/wordpress/init:$(TAG)" .
#	docker push "$(REGISTRY)/example/wordpress/init:$(TAG)"
#	@touch "$@"

# Relocate public postgres image to $REGISTRY.
.build/kong-ce/postgres: .build/var/REGISTRY \
                         .build/var/TAG \
                         | .build/kong-ce
	$(call print_target, $@)
	docker pull postgres:9.6
	docker tag postgres:9.6 "$(REGISTRY)/kong/kong-ce/postgres:$(TAG)"
	docker push "$(REGISTRY)/kong/kong-ce/postgres:$(TAG)"
	@touch "$@"

# Relocate ubbagent image to $REGISTRY.
#.build/wordpress/ubbagent: .build/ubbagent/ubbagent \             not using metering
#                           .build/var/REGISTRY \
#                           .build/var/TAG \
#                           | .build/wordpress
#	$(call print_target, $@)
#	docker tag "gcr.io/cloud-marketplace-tools/ubbagent" "$(REGISTRY)/example/wordpress/ubbagent:$(TAG)"
#	docker push "$(REGISTRY)/example/wordpress/ubbagent:$(TAG)"
#	@touch "$@"
