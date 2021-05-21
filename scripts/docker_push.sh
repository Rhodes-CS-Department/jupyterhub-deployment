#!/bin/bash

while true; do
  read -p "Enter version tag, with format YYYY_MM_DDrcVV: " -r
  case $REPLY in
    20[0-9][0-9]_[0-9][0-9]_[0-9][0-9]rc[0-9][0-9] ) export RC_VERSION=$REPLY; break;;
    * ) echo "Enter a correct value...";;
  esac
done

echo "Using $RC_VERSION..."
read -p "Tag and push with $RC_VERSION? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Run scripts/docker_push.sh to push when ready..."
  exit 1
fi

docker tag jserver:latest gcr.io/rhodes-cs/jserver:$RC_VERSION
echo
echo "Pushing..."
echo
docker push gcr.io/rhodes-cs/jserver:$RC_VERSION
echo
echo "Validate the version appears below:"
echo
gcloud container images list-tags gcr.io/rhodes-cs/jserver
echo
echo "Update config/config.yaml to update the container image version to $RC_VERSION."
echo "After updating, run scripts/helm_upgrade.sh to push the new config."
echo
