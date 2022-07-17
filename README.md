# Rhodes Jupyter Environment

Welcome to the Rhodes JupyterHub environment! This document contains:

1. An overview of JupyterHub and the JupyterHub-on-Kubernetes architecture.
1. Information for faculty users of the JupyterHub environment.
1. Information about how to configure and maintain the environment.
1. Troubleshooting information.
1. Documentation of the initial cluster design.

Here are some quick links, a full table of contents follows:

* [Notebook environment](https://rhodes-py.org)
* [Admin page](https://rhodes-py.org/hub/admin)
* [Kubernetes
  cluster](https://console.cloud.google.com/kubernetes/list?project=rhodes-cs)
* [CS Program GCP
  Project](https://console.cloud.google.com/home/dashboard?project=rhodes-cs)
* [Working with GitHub/nbgitpuller](#working-with-github-and-nbgitpuller) (this
  document)
* [Monitoring dashboards](#installing-and-running-the-dashboard) (this document)
* [Viewing the cluster](#viewing-the-cluster) (this document)
* [Administering user servers](#administering-user-servers) (this document)
* [Zero to Jupyterhub](https://zero-to-jupyterhub.readthedocs.io/en/latest/)

# Table of Contents
(Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc.go))

* [Cluster Architecture and Deployment](#cluster-architecture-and-deployment)
* [Teaching in the environment](#teaching-in-the-environment)
   * [Logins](#logins)
   * [Starting/restarting your server](#startingrestarting-your-server)
   * [Accessing student servers](#accessing-student-servers)
   * [Distributing Files to Students](#distributing-files-to-students)
      * [Working with GitHub and nbgitpuller](#working-with-github-and-nbgitpuller)
   * [COMP141 libraries](#comp141-libraries)
   * [Additional libraries](#additional-libraries)
   * [Integrating with okpy](#integrating-with-okpy)
   * [Using multiple okpy endpoints](#using-multiple-okpy-endpoints)
   * [Tips for authoring assignments](#tips-for-authoring-assignments)
* [Configuring the environment](#configuring-the-environment)
   * [Configure your local environment for administration](#configure-your-local-environment-for-administration)
   * [Configuring JupyterHub](#configuring-jupyterhub)
   * [Customizing the Docker image](#customizing-the-docker-image)
      * [Testing locally](#testing-locally)
      * [Manual building and pushing](#manual-building-and-pushing)
         * [Pushing the image to GCP](#pushing-the-image-to-gcp)
* [Troubleshooting and Administration](#troubleshooting-and-administration)
   * [Viewing the cluster](#viewing-the-cluster)
      * [kubectl verbs](#kubectl-verbs)
      * [Expected/example state](#expectedexample-state)
         * [Service](#service)
         * [Deployment](#deployment)
         * [Pods](#pods)
         * [Disk and claims](#disk-and-claims)
   * [Viewing logs](#viewing-logs)
   * [Administering user servers](#administering-user-servers)
   * [Accessing user files without a server](#accessing-user-files-without-a-server)
   * [Restarting deployments (not user servers)](#restarting-deployments-not-user-servers)
   * [Manually scaling](#manually-scaling)
   * [Installing and running the dashboard](#installing-and-running-the-dashboard)
   * [Culling users](#culling-users)
   * [Help docs](#help-docs)
* [Initial Cluster Setup](#initial-cluster-setup)
   * [GCE project configuration](#gce-project-configuration)
   * [Create Kubernetes cluster](#create-kubernetes-cluster)
* [Known issues](#known-issues)


# Cluster Architecture and Deployment

First, a brief overview of how JupyterHub works:
* There is a JupyterHub process running to manage single-user Jupyter servers.
  Users connect to this process and authenticate. After authenticating, a
  Jupyter server is spawned for that user.
* When users are running notebooks or managing their files, etc., they are
  communicating directly with their server.
* The main JupyterHub process can cull inactive servers, be used for server
  administration for admin users, etc.

In the Rhodes CS GCP project, there is a [Kubernetes](https://kubernetes.io/)
cluster running the JupyterHub deployment for the program. Kubernetes is a tool
for running and managing containers (in our case,
[Docker](https://docker-curriculum.com/) containers) on a cluster of physical
machines.

If you are not familiar with containers, think of them as lightweight virtual
machines. A _container image_ is the "disk image" for that VM, containing the
binaries that the virtual machine will run, the filesystem, etc.

In this cluster, there is a set of nodes/"physical" machines (GCE VMs) that is
running the main JupyterHub server. When a user logs in, a __user server__ is
spawned by JupyterHub. This is a container running the Jupyter server.

If there is not enough physical resources to run the user server, another node
is added to the cluster. When user servers time out and are reaped, creating
idle resources, these nodes are given back to GCE.

Users' home directories are stored on GCE persistent disks that are attached to
their containers when the containers are started. There is more detail about
this later in the document.

The JupyterHub deployment is configured in two ways:

* __The Helm chart__ that configures the JupyterHub application.
  [Helm](https://helm.sh) is package manager for Kubernetes. A Helm chart is a
  configuration of Kubernetes processes/resources. We use the chart template
  provided by the JupyterHub project (the repository is
  [here](https://jupyterhub.github.io/helm-chart/)), which configures the
  JupyterHub server, the network proxy, etc.

  We supply __values__ to fill in this template and customize our deployment of
  JupyterHub (`config/config.yaml`).  This configuration includes which docker
  container to run, how many resources should be provided to a server, how
  authentication works, etc.

* __The Docker container image__ that runs both user servers. The Jupyter
  project maintains a [set of container
  images](https://github.com/jupyter/docker-stacks/). However, we want to
  install some non-default libraries, so we have a custom container image for
  our deployment. This is configured in `config/Dockerfile` and is hosted in the
  GCP project
  [here](https://console.cloud.google.com/gcr/images/rhodes-cs?project=rhodes-cs).

  In this guide, there are instructions for configuring, building, and pushing
  this container image.

Authentication is done via OneLogin. We have integrated with the Rhodes OneLogin
production instance so that students and faculty can log in using their Rhodes
credentials. The cluster is open to all Rhodes students, though we plan to clean
up storage periodically.

# Teaching in the environment

## Logins

Students and faculty use Rhodes [OneLogin](https://rhodes.onelogin.com) to log into their
accounts. All Rhodes students have access to the cluster. 

On first login, a user's storage is initialized. Note that student work is
stored on separate disks; by default, the instructor cannot access the student
filesystem, except through using the [admin panel](#accessing-student-servers)
(although you can manually mount a student's disk, see [this
section](#accessing-user-files-without-a-server) for more information).

## Starting/restarting your server

If you want to start or stop your server once logged in, click on "Control
Panel" -- this will let you stop your currently-running server, and then restart
it. You may need to advise students to do this if they haven't restarted in a
long time and need to pick up library/file changes.

## Accessing student servers

Students may need help with their environment, or you may need to peek at
student work.

To access a student server, you have to be an administrator (configured in
`config/config.yaml`). To access the admin panel, click "Control Panel" then
"Admin" in the header bar of the environment. Here, you can see all student
accounts and servers.  Click "access server" to access a student's server (you
can also start or stop student servers from here as well).

Note that even though there's a scary "authorize" button, your activity is not
visible to the student.

## Distributing Files to Students

__For Spring '22:__ All users automatically sync [this Github
repo](https://github.com/Rhodes-CS-Department/comp141-sp22) on server start.

The deployment is configured to automatically update Rhodes-specific libraries
when a user logs in, by running `pip install` on [this
repository](https://github.com/Rhodes-CS-Department/comp141-libraries).

Distributing files to students is done by using
[nbgitpuller](https://github.com/jupyterhub/nbgitpuller), a tool that
automatically syncs files in a user's directory with a GitHub repository. The
tool is smart enough to do conflict resolution and hides the machinery of
cloning/updating a repo from the student.

To distribute a repository to a student, first make the repository public and
generate a URL for nbgitpuller using [this
generator](https://jupyterhub.github.io/nbgitpuller/link?hub=https://rhodes-notebook.org&branch=main).
Some configuration has been pre-populated. The generated url can then be
distributed to students (e.g., through Canvas).

It is also possible to configure JupyterHub to automatically run nbgitpuller
when a user's server starts. Instructions are
[here](https://zero-to-jupyterhub.readthedocs.io/en/latest/jupyterhub/customizing/user-environment.html#using-nbgitpuller-to-synchronize-a-folder).

### Working with GitHub and nbgitpuller

__WARNING:__ It is a best practice to __not__ delete or rename files in git
after they have been cloned by students. The merge behavior for `gitpuller` is
permissive, but has difficulty resolving some conflicts, particularly conflicts
where a file has been created/renamed in one branch and deleted in another.
__For your sanity, don't move or remove files after they are in students'
hands!__ See [Known issues](#known-issues), particularly
[#5](https://github.com/Rhodes-CS-Department/jupyterhub-deployment/issues/5).
__END WARNING__

~~As of Fall'21, the container image for servers does not contain ssh, so if you
use 2fa with GitHub, you will need to [create an access
token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
in order to use https authentication.~~ The current (12/30/21) image version contains ssh.

Then, __make sure you clone the repo to a separate directory__ than the
`nbgitpuller` synced one (currently `comp141-sp22`):

```
$ git clone https://github.com/Rhodes-CS-Department/comp141-sp22.git comp141-development
```

When making local changes to be reviewed/to shared resources, use a branch:

```
$ git checkout -b <my local branch>
...
$ git commit -m 'my changes'
$ git push --set-upstream origin <my local branch> # use your token to login if using 2fa
...
$ git checkout main
$ git pull
```

If you had changes in `main` but wanted to actually be working in a branch:

```
$ git stash # stash changes
$ git checkout -b <branch>
$ git stash pop # unstash changes in new branch
```

## COMP141 libraries

We use Rhodes-specific Python libraries for many assignments, which can be found
in [this repo](https://github.com/Rhodes-CS-Department/comp141-libraries).

~~These libraries are installed at every server startup, so any changes will be
propagated to student servers and do not require a notebook environment
restart.~~

In order to reduce startup time, these libraries are installed in the Docker
image, rather than on server start. This means that changes to the 141 libraries
require a rebuild of the Docker image and a version tag update followed by a
helm upgrade.

## Additional libraries

If you want to use additional libraries for your course, they must be added to
the server docker image. Please file an
[issue](https://github.com/Rhodes-CS-Department/jupyterhub-deployment/issues/new/choose)
for the student admins to install the library on the deployed image, or follow
the instructions in the [Customizing the Docker
Image](#customizing-the-docker-image) section.

## Integrating with okpy

We use [okpy](https://okpy.org) for student notebook submissions. Since okpy
only supports Google for authentication, students need to log in to okpy with a
Google account. In the past, we had students create Google accounts that
corresponded to their Rhodes email (see
[here](https://matthewlang.github.io/comp141/using_ok.html), for example) in
order to access the environment. Since we have moved to OneLogin, students no
longer do this. 

You can still require students to do so, or you can collect email accounts from
them. Then, you can use a setup like this for students in your course:

<img
src="https://storage.googleapis.com/comp141-public/configure_students.png"/>

## Using multiple okpy endpoints

Okpy is difficult to use with multiple instructors in the same course shell.
However, okpy config files require a course shell endpoint in order to submit
student work. The `c1.notebooks`
[library](https://github.com/Rhodes-CS-Department/comp141-libraries/blob/main/cs1/notebooks.py) in the 
[comp141-libraries](https://github.com/Rhodes-CS-Department/comp141-libraries)
allows instructors to distribute a template okpy config file with assigments.

Instead of distributing a `foo.ok` config file for assignment `foo`, instructors
will distribute a template file. The COMP141 library will create the correct
`foo.ok` config file from the template.

Template files must be named `.template.ok` (notice the `.`) and can contain an
endpoint placeholder value (`<#endpoint#>`). For example:

```
{
  "name": "Program 08",
  "endpoint": "<#endpoint#>/project08",
  "src": [
    "P8.ipynb",
    "imgfilter.py"
  ],
  "tests": {
      "tests/q*.py": "ok_test"
  },
  "protocols": [
      "file_contents",
      "grading",
      "backup"
  ]
}
```

This allows for course instructors to distribute a single template file per
project/lab, and for students to fill in the endpoint for their specific
instructor (allowing multiple instructors to have different endpoints).

The endpoint options should be JSON-encoded and can be distributed in a file
named `.options` or will be pulled from the following url:
[https://storage.googleapis.com/comp141-public/options.json]().

When a student runs the `ok_login` code...
```
from cs1.notebooks import *
ok_login('p8.ok')
```
they will be prompted to select an endpoint and the file `p8.ok` will be dropped
in the directory with the correct endpoint.

Endpoint selection is cached and will be used to automatically populate future
template assignments (e.g., this needs to be done once per semester).

See [this PR](https://github.com/Rhodes-CS-Department/comp141-libraries/pull/5)
for more info.

## Tips for authoring assignments

* It is preferable to use the `cs1.notebooks` wrapper for a lot of things, it
  automates logging the student in if they are logged out.
* Use the lock cells feature to lock cells you don't want students to edit.
* Use dependent cell execution if you want to make sure that cells are executed
  in a certain order (e.g., an earlier cell is a precondition for a later one).

# Configuring the environment

## Configure your local environment for administration

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
1. Run `gcloud auth configure-docker` in order to be able to push to `gcr.io`.
1. Install [Helm](https://helm.sh) following the instruction
   [here](https://helm.sh/docs/intro/install/), or on MacOS, run `brew install
   helm` if you are using homebrew.


## Configuring JupyterHub

`config/confg.yaml` contains the config for the JupyterHub instance. Any
__configuration changes__ for the cluster should modify this file.

Note that your helm version must be at least 3.2 in order to be compatible with
the current JupyterHub helm chart.

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

1. __Tokens:__ No secrets are stored in this repo; all tokens should be stored
   elsewhere in a `values.yaml` file. The path to this file is a parameter to
   `helm_upgrade.sh` (the next step).

1. Now, to push changes to `config.yaml` to the cluster, run `helm upgrade`
   using the included script:

   ```
   ./scripts/helm_upgrade.sh -s=path/to/secrets.yaml -d
   ```

   Note that the `-d` flag indicates tha this is a dry run and only the config
   will be printed. To actually run the update, remove `-d`.

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

Then, when you want to build and push the image, run:

```
./scripts/docker_build.sh
```

This script will do the Docker build and prompt whether you want to push the
newly-built image. 

If you choose to test locally and push later, you can run the following to
continue the push.

```
./scripts/docker_push.sh
```

__Important:__ Don't forget to update `config.yaml` with the new version tag and
run `helm_upgrade.sh` to push the config.

### Testing locally

You can confirm that the image was updated with `docker image ls`.

To test the container image locally, you can run the Docker image with the
following (the `-p` flag forwards the container's port 8888 to the local port
8888):

```
docker run -p 8888:8888 jserver
```

If you want to do development of course materials or libraries that are stored
locally, you can mount your local filesystem to the user home directory on the
locally-running container image with the following.

`docker run -p 8888:8888 -v /path/to/dir/to/mount:/home/jovyan/work jserver`

If you are developing libraries and experimenting with them in a notebook, it is
helpful to auto-reload them on changes:

```
%load_ext autoreload
%autoreload 2
```

### Manual building and pushing

__Note:__ It is preferrable to use the scripts `scripts/` for building and
pushing Docker images! Only do this if you know what you're doing.

To build the image:

`docker build -t jserver -f config/Dockerfile config/`

#### Pushing the image to GCP

Next we need to publish the image to the Rhodes container registry, so that
Kubernetes will start pulling the new image.

If you haven't configured Docker for GCP container registry, run the following:

```
gcloud auth configure-docker
```

Now, choose a release candidate version for the new image. The version should be
of the form `YYYY_MM_DDrcVV` where `VV` is used for multiple versions per day
(start with 00).

```
export RC_VERSION=YYYY_MM_DDrcVV
docker tag jserver:latest gcr.io/rhodes-cs/jserver:$RC_VERSION
docker image ls
docker push gcr.io/rhodes-cs/jserver:$RC_VERSION
```

Now you should see the container when you run `gcloud container images list`.
Additionally, you should see the the new release candidate tag when you run
`gcloud container images list-tags gcr.io/rhodes-cs/jserver`:

```
gcloud container images list-tags gcr.io/rhodes-cs/jserver
DIGEST        TAGS                   TIMESTAMP
48d50b385e28  2020_02_16rc01,latest  2021-02-16T15:54:46
fde1b612abad                         2021-02-14T18:06:17
e05babc291c6                         2021-01-24T21:32:16
6d4d44ff86d5                         2020-12-19T18:13:00
```

# Troubleshooting and Administration

## Viewing the cluster

You can use the `kubectl` command line tool to view the cluster state, or you
can use the [GCP
UI](https://console.cloud.google.com/kubernetes/list?project=rhodes-cs). In the
`jupyter` cluster, you can view the provisioned nodes, and persistent disks.

### `kubectl` verbs

`kubectl` has a few verbs that one should know in order to view and debug a
cluster:

* `kubectl get [api-resource]` -- list objects of type `api-resource` (use
  `kubectl api-resources` to list them all). The main ones for our purposes are
  `service`, `deployment`, `pod`, and `node`.
* `kubectl describe [api-resource] [resource-name]` -- view details for the
  particular resource (or all resources of the given type, if no resource name
  is given), including events.
* `kubectl logs [pod-name]` -- view logs (STDOUT) for a particular pod.
* `kubectl exec [pod-name] -- [command]` -- run a command within the given pod.
  Add the `-ti` flags to `exec` to run an interactive command (e.g., `bash`).
* `kubectl proxy` -- open a proxy to the cluster to access the cluster API and
  the API of all resources (through http verbs).

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
conceptual APIs with an endpoint, and are how different applications within the
same k8s cluster can find and communicate with one another. A service can be
backed by one or more containers/pods. In our deployment, the only services are
those for the hub itself (pointing to the `hub` deployment) and the JupyterHub
API and HTTP proxies that proxy traffic for a particular user to a particular
server (both pointing to the `proxy` deployment).

Anything that will be exposed to the outside world requires a service. Here,
only the public proxy is exposed publically. This proxy will route HTTPS to
internal services (i.e., hub traffic to the hub and user traffic to user
servers).

The `proxy-public` service points to `autohttps`, which is running
[Traefik](https://traefik.io/traefik/) to route requests to internal services.

Note that services _no not_ correspond 1:1 with pods or even deployments.
Services use [labels and
selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
to match pods.

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

~~Note that right now there is not a great way to delete PVCs when a user is
deleted. There is a
[discussion](https://discourse.jupyter.org/t/a-cull-idle-user-service-that-deletes-pvs/4742/11)
about this and issues tracked
[here](https://github.com/jupyterhub/jupyterhub-idle-culler/issues/8) and
[here](https://github.com/jupyterhub/kubespawner/issues/446).~~

As of 12/30/21, we have deployed a new JupyterHub version that includes a hook
for deleting PVCs when a user is deleted. Users can be deleted via the UI or via
the tool in `scripts/tools` (see the section on [culling
users](#culling-users)).

## Viewing logs

You can view logs in two ways: using `kubectl` or using the [Cloud Log
viewer](https://console.cloud.google.com/logs/query?project=rhodes-cs).

To view the logs for a particular pod, you can list pods, and then get its logs:

```
kubectl get pods -n jhub
kubectl logs <pod name> -n jhub
```

__Note:__ Logs for the post-startup script are not collected, since these are
commands run inside the pod, after it has started. The logs for the `pip
install` of the COMP141 libraries and `nbgitpuller` are redirected to
`/tmp/startup_logs` which can be viewed by logging into the student's server.
These __do not persist__ across pod restarts.

See [this issue](https://github.com/kubernetes/kubernetes/issues/16412) for
context. If `postStart` fails, this would be published as an event for the pod;
however, we swallow failures in our startup script, and therefore no events are
published.

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

## Accessing user files without a server

It is possible for a user to make changes to their home directory in a way that
prevents their server from starting. If, for example, they prevent nbgitpuller
from running successfully, this may cause the startup script for the server to
fail. This is tracked in #5.

In that case, you might want to access a user's file system. In order to do
this, you will need to create a temporary virtual machine, attach the user's
home directory to it, and modify their file system.

First, find the disk that corresponds to the user:

```
[lang@eschaton ~/courses/141]$ kubectl -n jhub get pvc | grep langma
NAME                            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
claim-langma-40gmail-2ecom      Bound    pvc-8df5bbf0-e119-461d-90d1-51cfd81168e5   1Gi        RWO            standard       30d
```

The `pvc-<GUID>` is the name of the user's disk. To access it, create a VM
instance and then follow the procedure for adding a disk to the VM (outlined
[here](https://cloud.google.com/compute/docs/disks/add-persistent-disk#console).
Note that in those instructions, you will be attaching a new disk, but in our
case, you will want to choose an existing disk, and use the disk name you found
above.

After this step, you can [ssh
into](https://cloud.google.com/compute/docs/instances/connecting-to-instance#connecting_to_vms)
the new VM and mount/edit the disk.

```
$ sudo su
$ mkdir debug
$ mount /dev/sdb debug
$ cd debug
$ ...
```

## Restarting deployments (not user servers)

```
kubectl -n jhub get deployment
kubectl -n jhub rollout restart deployment <deployment name>
```

## Manually scaling

If user servers cannot schedule themselves, users will see an error message
indicating that there are not enough nodes to schedule their pod. When this
happens, the user pool needs to be scaled up. Autoscaling should take care of
this normally, but if manual intervention is required, you can manually scale
the pool up.

__Using `gcloud`:__

```
gcloud container clusters resize \
    jupyter \
    --node-pool user-pool \
    --num-nodes [new size] \
    --zone us-central1-a
```

It will take a few moments for the pool to scale up.

__Using the UI:__

* Go to the [User Pool
  config](https://console.cloud.google.com/kubernetes/nodepool/us-central1-a/jupyter/user-pool?project=rhodes-cs)
  in the Cloud Console.
* Click "EDIT" and manually change the "Number of nodes" field to a higher
  number.
* Click "Save." It will take a few moments for the node pool to scale up.



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

## Culling users

There is Python code to remove users (and PVCs) under `scripts/tools`.

To run, you will need to grant yourself an OAuth token to use for the script to
take action on your behalf. From the [token
page](https://rhodes-notebook.org/hub/token) click "Request new API token" and
copy the token that is generated.

Then, to run the script, first run in dry run mode (default), to see that the
users that will be deleted are expected:

```
pipenv run python cull_users.py --token YOUR_OAUTH_TOKEN
```

Then, run the script in non-dry run mode:

```
pipenv run python cull_users.py --token YOUR_OAUTH_TOKEN --no_dry_run
```

## Help docs

The
[Zero-to-JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/debug.html)
docs have information about debugging, and other FAQ topics.

# Initial Cluster Setup

The initial cluster setup was done using the [Zero to JupyterHub with Kubernetes
guide](https://zero-to-jupyterhub.readthedocs.io/en/latest/).

## GCE project configuration

Outside of the guide, there are a few cloud resources that I manually set up.

* Appropriate APIs are already enabled for the project (GKE, logging,
  containers, etc.).
* There's a static external IP address provisioned that is in use by the
  cluster's proxy server. This is configured in `config/config.yaml`. You can
  see this
  [here](https://console.cloud.google.com/networking/addresses/list?project=rhodes-cs).

## Create Kubernetes cluster

1. Create the Kubernetes cluster by running `./scripts/create_cluster.sh`.
1. You can verify that the cluster exists by running `kubectl get node`
1. Create a pool of user nodes by running `./scripts/create_node_pool.sh` (you
   might have to update your Cloud SDK to install beta components).

The cluster creation script enrolls the cluster in the GKE `stable` release
channel, which will cause the cluster to receive automatic version updates from
GCP. This in turn results in the node pools receiving image version updates.


# Known issues

* If a user deletes a file, then the file is deleted from the `nbgitpuller`
  origin repo, this can make a user's server inaccessible until the conflict is
  fixed. Can be mitigated by switching from a single repo to per-assignment
  repos (at least then the server is accessible).
  * Tracked in issue
  [#5](https://github.com/Rhodes-CS-Department/jupyterhub-deployment/issues/5).
  * Mitigation is to fix the user directory/repo 
    (see [this section](#accessing-user-files-without-a-server)).
