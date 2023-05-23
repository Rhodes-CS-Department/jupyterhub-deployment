gcloud container clusters upgrade 'jupyter' --project 'rhodes-cs' --zone 'us-central1-a' --image-type 'COS_CONTAINERD' --node-pool 'default-pool'
gcloud container clusters upgrade 'jupyter' --project 'rhodes-cs' --zone 'us-central1-a' --image-type 'COS_CONTAINERD' --node-pool 'notebook-pool'
