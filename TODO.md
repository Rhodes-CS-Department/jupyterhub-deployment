# TODO for AY 2020-2021

## Plan for Monday:

1. Copy any disks that need to be copied for faculty.
2. ~~Decide whether to delete existing cluster or to update in-place.~~
3. ~~Create new cluster~~ (or update machine type configs for existing).
4. If keeping existing, delete users and PVCs for existing users (this should
   reclaim PVs).
5. ~~Comb through configs, make sure nothing major has changed between 0.9.0 and
   0.11.1.~~
6. ~~Update OneLogin config.~~
7. ~~Remove GitHub sync of Spring'21 repo.~~
8. ~~Create Fall'21 repo and add that to config.~~
9. ~~Bring up new cluster.~~
10. ~~Make sure that logins and libraries work with new cluster.~~
11. Validate quota+autoscaling by bumping user placeholders to ~70.
12. ~~Rebuild docker image to pick up latest scipy image.~~
13. Update README with any configuration changes.
14. Update README with OneLogin documentation.
15. File issues for ~August work (rebuild Docker image, anything else?).
16. Discuss + consider options for [endpoint
    PR](https://github.com/Rhodes-CS-Department/comp141-libraries/pull/5).

### OneLogin config

* Looks like directions changed between [current
  stable](https://zero-to-jupyterhub.readthedocs.io/en/stable/administrator/authentication.html#genericoauthenticator-openid-connect)
  and
  [0.9.0](https://zero-to-jupyterhub.readthedocs.io/en/0.9.0/administrator/authentication.html#openid-connect).
  We will get things working with 0.9.0 and then fix our config when we update
  to stable.
* Update `README.md` with info about how logins are handled.
* ~~Use `hub.extraConfig` for the config described in [this
  issue](https://github.com/Rhodes-CS-Department/jupyterhub-deployment/issues/15).
  Follow instructions from
  [here](https://zero-to-jupyterhub.readthedocs.io/en/stable/administrator/advanced.html#arbitrary-extra-code-and-configuration-in-jupyterhub-config-py).~~
* ~~Update config with appropriate admin users (faculty + TLs).~~

### Parameter tweaking and GCP config

* Container size optimization, use data from [this
  issue](https://github.com/Rhodes-CS-Department/jupyterhub-deployment/issues/4).
* Validate that [project
  quotas](https://console.cloud.google.com/iam-admin/quotas?project=rhodes-cs)
  will be sufficient for fall load (~100 students).

### Hub updates

* Update helm chart version to [latest
  stable](https://jupyterhub.github.io/helm-chart/).
* Work with Kirlin, Sanders, and Welsh to iterate and merge [endpoint
  PR](https://github.com/Rhodes-CS-Department/comp141-libraries/pull/5).
* Set up fall 2021 and spring 2022 GitHub repos.
* Add fall 2021 repo to the hub config.


