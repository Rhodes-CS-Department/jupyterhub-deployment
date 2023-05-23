#!/bin/bash

path=${0%/*}
. $path/select.incl

printf "Building Docker image %s...\n" $image_name
docker build -t $image_name -f $dockerfile config/

if [ $? -ne 0 ]; then
  printf "Build failed!\n"
  exit $status
fi

printf "\nBuilt successfully...\n"
printf "Run the following to test locally, then open a browser to localhost:8888:\n\ndocker run -p 8888:8888 %s\n\n\n" $image_name

read -p "Continue to tag and push to GCP now (or you can run scripts/docker_push.sh at any time)? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  printf "Run scripts/docker_push.sh to push when ready...\n"
  exit 1
fi

./scripts/docker_push.sh $image
