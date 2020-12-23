# Rhodes Jupyter Environment

The CS program has a GCE
[project](https://console.cloud.google.com/home/dashboard?project=rhodes-cs).

# Configure your environment

1. The Kubernetes Engine API is already enabled for the project.
1. Install `gcloud` via its [install page](https://cloud.google.com/sdk/install)
1. Run `gcloud init` and log in to the Rhodes CS project.
1. Install `kubectl` by running `gcloud components install kubectl`.
1. Give your account permissions to perform all admin actions necessary by
   running `./scripts/cluster_permissions.sh your-google-account`
1. Follow the instruction [here](https://helm.sh/docs/intro/install/), or on
   MacOS, run `brew install helm` if you are using homebrew.

# Initial Cluster Setup

These initial setup steps follow the [Zero to JupyterHub with Kubernetes
guide](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

## GCE project configuration

Outside of the guide, there are a few cloud resources that I manually set up.

* There's a static external IP address provisioned that is in use by the
  cluster's proxy server. This is configured in `config/config.yaml`. You can
  see this
  [here](https://console.cloud.google.com/networking/addresses/list?project=rhodes-cs).
* I set up the project's OAuth [consent
  screen](https://console.cloud.google.com/apis/credentials/consent?project=rhodes-cs)
  and OAuth
  [credentials](https://console.cloud.google.com/apis/credentials?project=rhodes-cs).
* The login flow is configured in `config/config.yaml` and uses these
  credentials.

## Create Kubernetes cluster

1. Create the Kubernetes cluster by running `./scripts/create_cluster.sh`.
1. You can verify that the cluster exists by running `kubectl get node`
1. Create a pool of user nodes by running `./scripts/create_node_pool.sh` (you
   might have to update your Cloud SDK to install beta components).

# JupyterHub and Docker configs

## Configuring JupyterHub

`config/confg.yaml` contains the config for the JupyterHub instance. Any
__configuration changes__ for the cluster should modify this file.

1. One time set up: Make Helm aware of the [JupyterHub Helm chart
   repo](https://jupyterhub.github.io/helm-chart/):

   ```
   helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
   ```

1. When you want to update the config, pull the latest changes from the helm
   repo.

   ```
   helm repo update
   ```

1. Now, install the chart configured by `config.yaml` by running this command:

   ```
   ./scripts/helm_upgrade.sh
   ```

   This is the step that actually installs JupyterHub, so it might take a little
   bit.

1. Once this is complete, you can run the following to get the public IP
   address of the http proxy for JupyterHub:

   ```
   kubectl get service --namespace jhub
   ```


## Customizing the Docker image

As you can see in `config/config.yaml` under the `singleuser` node, we use a
custom Docker container with tools installed that we want.

The Docker container used for user servers is defined in `config/Dockerfile`.
Any changes to the user's image must be made by editing this file.

Make sure that you have [installed
Docker](https://hub.docker.com/editions/community/).

In `config/Dockerfile`, make the desired changes.

Then, when you want to build the image, run:

`docker build -t jserver -f Dockerfile config/`

You can confirm that the image was updated with `docker image ls` and can run
the server as a container with `docker run -p 443:443 jserver` (the `-p`
option forwards port 443.

Next we need to publish the image to the Rhodes container registry, so that
Kubernetes will start pulling the new image.

If you haven't configured Docker for GCP container registry, run the following:

```
gcloud auth configure-docker
```


```
docker tag jserver:latest gcr.io/rhodes-cs/jserver
docker image ls
docker push gcr.io/rhodes-cs/jserver
```

Now you should see the container when you run `gcloud container images list`.

# Troubleshooting and Administration

## Viewing the cluster

You can use the `kubectl` command line tool to view the cluster state, or you
can use the [GCP
UI](https://console.cloud.google.com/kubernetes/list?project=rhodes-cs). In the
`jupyter` cluster, you can view the provisioned nodes, and persistent disks.

You can view services and pods with:

```
kubectl get service --namespace=jhub
kubectl get pod --namespace=jhub
```

Pods will show you all slots for containers. 

If you want to view details about a pod, including recent events, you can run
`kubectl describe` to view pod details:

```
kubectl --namespace=jhub describe pod <pod name> 
```

The `describe` command can also be used with services and other resources.

The recent events listed by describe are useful for finding errors. To dig
deeper, you cna use `kubectl logs` to view logs (or use the Logs UI in GCP).

### Expected/example state

TODO add descriptions of system state

Pods:
```
[lang@eschaton ~]$ kubectl --namespace=jhub get pods
NAME                              READY   STATUS    RESTARTS   AGE
autohttps-b59c8d84f-8hnzz         2/2     Running   0          3m5s
continuous-image-puller-4hjxt     1/1     Running   0          4h17m
hub-6cc79f5bb-wp794               1/1     Running   0          73m
jupyter-langma-40gmail-2ecom      1/1     Running   0          118s
proxy-5784b6b988-568ct            1/1     Running   0          4h18m
user-placeholder-0                1/1     Running   0          4h18m
user-placeholder-1                1/1     Running   0          4h18m
user-placeholder-2                1/1     Running   0          4h18m
user-scheduler-7588c8977d-9n9z4   1/1     Running   0          4h18m
user-scheduler-7588c8977d-v4knn   1/1     Running   0          4h18m
```

Service:
```
[lang@eschaton ~]$ kubectl --namespace=jhub get service
NAME           TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S) AGE
hub            ClusterIP      10.3.245.111   <none>           8081/TCP 4h19m
proxy-api      ClusterIP      10.3.251.117   <none>           8001/TCP 4h19m
proxy-http     ClusterIP      10.3.241.81    <none>           8000/TCP 73m
proxy-public   LoadBalancer   10.3.243.111   35.225.189.212 443:31835/TCP,80:32140/TCP   4h19m
```

Deployment:
```
[lang@eschaton ~]$ kubectl --namespace=jhub get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
autohttps        1/1     1            1           73m
hub              1/1     1            1           4h20m
proxy            1/1     1            1           4h20m
user-scheduler   2/2     2            2           4h20m
```

Disk:
```
[lang@eschaton ~]$ kubectl --namespace=jhub get persistentvolumeclaim
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
claim-langma-40gmail-2ecom   Bound    pvc-8df5bbf0-e119-461d-90d1-51cfd81168e5   1Gi        RWO            standard       6m49s
hub-db-dir                   Bound    pvc-58ed8e5b-6b4e-45c2-aef1-7c70b89c3a35   1Gi        RWO            standard       4h23m

[lang@eschaton ~]$ kubectl --namespace=jhub get persistentvolume
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS   REASON   AGE
pvc-58ed8e5b-6b4e-45c2-aef1-7c70b89c3a35   1Gi        RWO            Delete           Bound    jhub/hub-db-dir                   standard                4h23m
pvc-8df5bbf0-e119-461d-90d1-51cfd81168e5   1Gi        RWO            Delete           Bound    jhub/claim-langma-40gmail-2ecom   standard                6m55s
```

## Viewing logs

You can view logs in two ways: using `kubectl` or using the [Cloud Log
viewer](https://console.cloud.google.com/logs/query?project=rhodes-cs).

To view the logs for a particular pod, you can list pods, and then get its logs:

```
kubectl get pods --namespace=jhub
kubectl logs <pod name> --namespace=jhub
```

## Restarting deployments

```
kubectl --namespace=jhub get deployment
kubectl --namespace=jhub rollout restart deployment <deployment name>
```

## Manually scaling

```
gcloud container clusters resize \
    <CLUSTER-NAME> \
    --num-nodes <NEW-SIZE> \
    --zone us-central1-a
```

## Help docs

The
[Zero-to-JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/debug.html)
docs have information about debugging, and other FAQ topics.
