#!/bin/sh

gcloud beta container node-pools create notebook-pool \
  --machine-type n1-highmem-2 \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 20 \
  --node-labels hub.jupyter.org/node-purpose=user \
  --node-taints hub.jupyter.org_dedicated=user:NoSchedule \
  --zone us-central1-a \
  --cluster jupyter

