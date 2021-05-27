#!/bin/bash

RELEASE=jhub
NAMESPACE=jhub

helm upgrade --cleanup-on-fail \
  --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE \
  --create-namespace \
  --version=0.11.1 \
  --values config/config.yaml \
  --set global.safeToShowValues=true
