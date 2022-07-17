#!/bin/bash

RELEASE=jhub
NAMESPACE=jhub

dry_run=""
secrets=""
while [ $# -gt 0 ]; do
  case "$1" in
    -s=*)
      secrets="${1#*=}"
      ;;
    -d)
      dry_run="--dry-run --debug"
      ;;
    *)
      echo "Invalid argument"
      exit 1
  esac
  shift
done


if [ -z "$secrets" ]; then
  echo '-s must be supplied with a secrets values.yaml file..'
  exit 1
fi

if [ -z "$dry_run" ]; then
  echo 'No dry run... upgrading in 2s...'
  sleep 2
fi

helm upgrade --cleanup-on-fail \
  --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE \
  --create-namespace \
  --version=1.2.0 \
  $dry_run \
  --values $secrets \
  --values config/config.yaml 
