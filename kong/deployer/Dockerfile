FROM launcher.gcr.io/google/debian9 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext

ADD schema.yaml /tmp/schema.yaml

# Provide registry prefix and track for default values for images.
ARG REGISTRY
ARG TRACK
RUN cat /tmp/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "TRACK=$TRACK" envsubst \
    > /tmp/schema.yaml.new \
    && mv /tmp/schema.yaml.new /tmp/schema.yaml


FROM gcr.io/cloud-marketplace-tools/k8s/deployer_envsubst

COPY manifest /data/manifest
COPY apptest/deployer /data-test/
COPY --from=build /tmp/schema.yaml /data/
