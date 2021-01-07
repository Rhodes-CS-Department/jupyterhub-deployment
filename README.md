# Rhodes Jupyter Environment

TODO:

* Add `nbgitpuller` sync and `pip install` of CS1 libraries on container startup.
* Write HOWTO for `nbgitpuller` assignment distribution through Canvas.

Quick links:

* [Notebook environment](https://rhodes-py.org)
* [Admin page](https://rhodes-py.org/hub/admin)
* [Zero to Jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/)
* [CS Program GCP
  Project](https://console.cloud.google.com/home/dashboard?project=rhodes-cs)
* [Kubernetes
  cluster](https://console.cloud.google.com/kubernetes/list?project=rhodes-cs)
* [Monitoring dashboards](#installing-and-running-the-dashboard) (this document)
* [Viewing the cluster](#viewing-the-cluster) (this document)
* [Administering user servers](#administering-user-servers) (this document)

# Configure your local environment for administration

1. Install `gcloud` via its [install page](https://cloud.google.com/sdk/install)
   and log in to the Rhodes CS project.

   ```
   gcloud init
   gcloud config set project rhodes-cs
   gcloud auth login
   ```

   You should have received an email when I added you to the Rhodes GCP project.
   Use that email to log in.
1. Install `kubectl` by running `gcloud components install kubectl`.
1. Generate a `kubeconfig` entry for the JupyterHub cluster:
   
   ```
   gcloud container clusters get-credentials jupyter --zone=us-central1-a
   ```

   This will allow you to control the cluster with the `kubectl` command line
   tool. You can read the explanation
   [here](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl).
1. Give your account permissions to perform all admin actions necessary by
   running `./scripts/cluster_permissions.sh your-google-account`
1. Install [Docker](https://hub.docker.com/editions/community/).
1. Install [Helm](https://helm.sh) following the instruction
   [here](https://helm.sh/docs/intro/install/), or on MacOS, run `brew install
   helm` if you are using homebrew.

# Initial Cluster Setup

These initial setup steps follow the [Zero to JupyterHub with Kubernetes
guide](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

## GCE project configuration

Outside of the guide, there are a few cloud resources that I manually set up.

* Appropriate APIs are already enabled for the project (GKE, logging,
  containers, etc.).
* There's a static external IP address provisioned that is in use by the
  cluster's proxy server. This is configured in `config/config.yaml`. You can
  see this
  [here](https://console.cloud.google.com/networking/addresses/list?project=rhodes-cs).
* In order to use Google authentication for the environment, this project is
  configured as an app:
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

   __Warning:__ This will create a brief outage where the service is
   unavailable, so don't make config changes frequently.


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

### Expected/example state

#### Service

```
[lang@eschaton ~]$ kubectl -n jhub get service
NAME           TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S) AGE
hub            ClusterIP      10.3.245.111   <none>           8081/TCP 4h19m
proxy-api      ClusterIP      10.3.251.117   <none>           8001/TCP 4h19m
proxy-http     ClusterIP      10.3.241.81    <none>           8000/TCP 73m
proxy-public   LoadBalancer   10.3.243.111   35.225.189.212 443:31835/TCP,80:32140/TCP   4h19m
```

[Services](https://kubernetes.io/docs/concepts/services-networking/service/) are
conceptual APIs with an endpoint. A service can be backed by one or more
containers/pods, but 

#### Deployment

```
[lang@eschaton ~]$ kubectl -n jhub get deployment
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
autohttps        1/1     1            1           73m
hub              1/1     1            1           4h20m
proxy            1/1     1            1           4h20m
user-scheduler   2/2     2            2           4h20m
```

A
[deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
is a set of replicas of pods. In this configuration, we have one replica in each
deployment, except for two pods for the user to node scheduler, which are
running leader election.

#### Pods

A [pod](https://kubernetes.io/docs/concepts/workloads/pods/) is an instance of a
running container (or set of grouped containers). Each pod is assigned a single
IP address and can be thought of conceptually as a single virtual machine. Pods
run on "physical" VMs called
[nodes](https://kubernetes.io/docs/concepts/architecture/nodes/), with multiple
pods per node. You can see the restrictions on co-residency in `config/config.yaml`.

```
[lang@eschaton ~/dsrc/jupyter]$ kubectl -n jhub get pod -o wide
NAME                              READY   STATUS    RESTARTS   AGE     IP          NODE                                     NOMINATED NODE   READINESS GATES
autohttps-b59c8d84f-8hnzz         2/2     Running   0          43h     10.0.0.25   gke-jupyter-default-pool-23a4322a-qdpl   <none>           <none>
continuous-image-puller-4hjxt     1/1     Running   0          2d      10.0.1.3    gke-jupyter-user-pool-175a3536-chnf      <none>           <none>
hub-6cc79f5bb-wp794               1/1     Running   0          45h     10.0.0.22   gke-jupyter-default-pool-23a4322a-qdpl   <none>           <none>
jupyter-langma-40gmail-2ecom      1/1     Running   0          2m34s   10.0.1.13   gke-jupyter-user-pool-175a3536-chnf      <none>           <none>
proxy-5784b6b988-568ct            1/1     Running   0          2d      10.0.0.14   gke-jupyter-default-pool-23a4322a-qdpl   <none>           <none>
user-placeholder-0                1/1     Running   0          2d      10.0.1.4    gke-jupyter-user-pool-175a3536-chnf      <none>           <none>
user-placeholder-1                1/1     Running   0          2d      10.0.1.2    gke-jupyter-user-pool-175a3536-chnf      <none>           <none>
user-placeholder-2                1/1     Running   0          2d      10.0.1.5    gke-jupyter-user-pool-175a3536-chnf      <none>           <none>
user-scheduler-7588c8977d-9n9z4   1/1     Running   0          2d      10.0.0.13   gke-jupyter-default-pool-23a4322a-qdpl   <none>           <none>
user-scheduler-7588c8977d-v4knn   1/1     Running   0          2d      10.0.0.12   gke-jupyter-default-pool-23a4322a-qdpl   <none>           <none>
```

Note the `-o wide` flag. This shows what nodes each pod is running on, as well
as their IP addresses.

You can see from the response that there is one Jupyter server running (for
`langma@gmail.com`). The `hub` pod is the JupyterHub server. `autohttps` and
`proxy` are the SSL certificate creator and network proxy. `user-scheduler` has
two instances (running leader election) and will map users to nodes (VMs). The
`user-placeholder` pods are dummy containers that ensure that there are free
slots for new arrivals.

__Pod state and logs:__ 

If you want to view details about a pod, including recent events, you can run
`kubectl describe` to view pod details:

```
kubectl -n jhub describe pod <pod name> 
```

The `describe` command can also be used with services and other resources.

The recent events listed by describe are useful for finding errors. To dig
deeper, you cna use `kubectl logs` to view logs (or use the Logs UI in GCP).

#### Disk and claims

In our configuration, users have a GCE [Persistent
Disk](https://cloud.google.com/compute/docs/disks/add-persistent-disk) that is
their home directory. Persistent disks can be _attached_ to any VM running in GCP
and then mounted onto the Linux filesystem.

When a user first logs in, a 1G storage claim ([persistent volume
claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)) is
created, and the Kubernetes master creates a persistent disk to satisfy that
claim. The size of the claim is configured in `singleusesr/storage/capacity` in
`config/config.yaml`.

When a pod is created for the user's server, the disk is attached to the node
running the pod, and the volume is mounted as the user's home directory.

```
[lang@eschaton ~]$ kubectl -n jhub get persistentvolumeclaim
NAME                         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
claim-langma-40gmail-2ecom   Bound    pvc-8df5bbf0-e119-461d-90d1-51cfd81168e5   1Gi        RWO            standard       6m49s
hub-db-dir                   Bound    pvc-58ed8e5b-6b4e-45c2-aef1-7c70b89c3a35   1Gi        RWO            standard       4h23m

[lang@eschaton ~]$ kubectl -n jhub get persistentvolume
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                             STORAGECLASS   REASON   AGE
pvc-58ed8e5b-6b4e-45c2-aef1-7c70b89c3a35   1Gi        RWO            Delete           Bound    jhub/hub-db-dir                   standard                4h23m
pvc-8df5bbf0-e119-461d-90d1-51cfd81168e5   1Gi        RWO            Delete           Bound    jhub/claim-langma-40gmail-2ecom   standard                6m55s
```

Here you can see that since only I have logged in, there are only two claims:
one for the JupyterHub user and one for me. They are backed by two GCE
persistent disks.

When volume claims are deleted, so are the corresponding disks (reclaim policy).

Note that right now there is not a great way to delete PVCs when a user is
deleted. There is a
[discussion](https://discourse.jupyter.org/t/a-cull-idle-user-service-that-deletes-pvs/4742/11)
about this and issues tracked
[here](https://github.com/jupyterhub/jupyterhub-idle-culler/issues/8) and
[here](https://github.com/jupyterhub/kubespawner/issues/446).

Since we are talking about a few hundred GB for a year or so, the cost is not
that high, and we might just consider redeploying the entire cluster yearly.

## Viewing logs

You can view logs in two ways: using `kubectl` or using the [Cloud Log
viewer](https://console.cloud.google.com/logs/query?project=rhodes-cs).

To view the logs for a particular pod, you can list pods, and then get its logs:

```
kubectl get pods -n jhub
kubectl logs <pod name> -n jhub
```

## Administering user servers

The easiest way to administer user servers is via the
[admin](https://rhodes-py.org/hub/admin) page. This allows you to log in to user
servers, kill and restart them, etc.

Once you've logged in to a user server, you can run a terminal through the
JupyterHub interface.

If, however, you want to ssh into their pod _without_ going through their
Jupyter server, you can execute commands on the pod using `kubectl exec`.

For example, to run an interactive bash shell, run:

```
kubectl -n jhub exec -it [pod name] /bin/bash
```

Use `--` to run command with flags:

```
[lang@eschaton ~]$ kubectl -n jhub exec jupyter-langma-40gmail-2ecom -- ls -lh
total 20K
drwxrws--- 2 root   users 16K Dec 23 00:48 lost+found
-rw-r--r-- 1 jovyan users  72 Dec 24 21:21 Test.ipynb
```

## Restarting deployments (not user servers)

```
kubectl -n jhub get deployment
kubectl -n jhub rollout restart deployment <deployment name>
```

## Manually scaling

```
gcloud container clusters resize \
    jupyter \
    --node-pool [default-pool|user-pool]
    --num-nodes [new size] \
    --zone us-central1-a
```

## Installing and running the dashboard

Both the [GCP
page](https://console.cloud.google.com/kubernetes/clusters/details/us-central1-a/jupyter/details?project=rhodes-cs)
and the Cloud Monitoring
[dashboard](https://console.cloud.google.com/monitoring/dashboards/resourceList/kubernetes?project=rhodes-cs&pageState=(%22interval%22:()))
has telemetry data about the cluster.

There is also a dashboard monitor that was installed alongside the cluster with
the following:

```
# Install dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

# Create admin service account for dashboard, and give it admin permissions
kubectl create serviceaccount admin-user -n kubernetes-dashboard
kubectl create clusterrolebinding dash-cluster-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kubernetes-dashboard:admin-user
```

To view and login to the dashboard, run the following:

```
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

Copy the `token` from the results. This is the bearer token of the dashboard
service account.

Then run `kubectl proxy` to create a gateway between your local machine and the
Kubernetes API server. The dashboard is accessible at
[http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/]().

Use the token you copied to log in. Select the namespace `jhub` from the
namespace drop down to view the JupyterHub telemetry.

## Help docs

The
[Zero-to-JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/debug.html)
docs have information about debugging, and other FAQ topics.
