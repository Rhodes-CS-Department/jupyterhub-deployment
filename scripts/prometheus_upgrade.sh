#!/bin/bash

RELEASE=prometheus
NAMESPACE=prometheus

helm upgrade --cleanup-on-fail \
  --install $RELEASE prometheus-community/prometheus \
  --namespace $NAMESPACE \
  --create-namespace \
  --values config/prometheus.yaml \
  --set global.safeToShowValues=true
