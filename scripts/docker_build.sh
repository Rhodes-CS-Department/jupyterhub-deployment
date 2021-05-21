#!/bin/bash

echo "Building Docker image..."
docker build -t jserver -f config/Dockerfile config/

if [ $? -ne 0 ]; then
  echo "Build failed!"
  exit $status
fi

echo
echo "Built successfully..."
echo -e "Run the following to test locally, then open a browser to localhost:8888:\n\ndocker run -p 8888:8888 jserver"
echo
echo

read -p "Continue to tag and push to GCP now (or you can run scripts/docker_push.sh at any time)? " -n 1 -r
echo 
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Run scripts/docker_push.sh to push when ready..."
  exit 1
fi

./scripts/docker_push.sh
