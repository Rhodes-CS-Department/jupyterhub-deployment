#!/bin/bash

path=${0%/*}
. $path/select.incl

while true; do
  read -p "Enter version tag, with format YYYY_MM_DDrcVV: " -r
  case $REPLY in
    20[0-9][0-9]_[0-9][0-9]_[0-9][0-9]rc[0-9][0-9] ) export RC_VERSION=$REPLY; break;;
    * ) printf "Enter a correct value...\n";;
  esac
done

printf "Using %s...\n" $RC_VERSION
read -p "Tag and push with $RC_VERSION? " -n 1 -r
printf "\n"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  printf "Run scripts/docker_push.sh to push when ready..."
  exit 1
fi

docker tag $image_name:latest gcr.io/rhodes-cs/$image_name:$RC_VERSION

printf "\nPushing...\n\n"
docker push gcr.io/rhodes-cs/$image_name:$RC_VERSION

printf "\nValidate the version appears below:\n\n"
gcloud container images list-tags gcr.io/rhodes-cs/$image_name

printf "\nUpdate config/config.yaml to update the container image version to $RC_VERSION.\n\n"
printf "After updating, run scripts/helm_upgrade.sh to push the new config.\n\n"
