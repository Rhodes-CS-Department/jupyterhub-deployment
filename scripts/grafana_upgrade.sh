#!/bin/bash

RELEASE=grafana
NAMESPACE=grafana

helm upgrade --cleanup-on-fail \
  --install $RELEASE grafana/grafana \
  --namespace $NAMESPACE \
  --create-namespace \
  --values config/grafana_config.yaml \
  --set global.safeToShowValues=true
