#!/bin/bash

gcloud container clusters create \
  --machine-type n1-standard-2 \
  --num-nodes 1 \
  --zone us-central1-a \
  --cluster-version latest \
  --release-channel stable \
  jupyter
