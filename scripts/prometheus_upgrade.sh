#!/bin/bash

RELEASE=prometheus
NAMESPACE=prometheus

helm upgrade --cleanup-on-fail \
  --install $RELEASE prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --create-namespace \
  --values config/monitoring_config.yaml \
  --set global.safeToShowValues=true
