# TODO for AY 2020-2021

### OneLogin config

* Looks like directions changed between [current
  stable](https://zero-to-jupyterhub.readthedocs.io/en/stable/administrator/authentication.html#genericoauthenticator-openid-connect)
  and
  [0.9.0](https://zero-to-jupyterhub.readthedocs.io/en/0.9.0/administrator/authentication.html#openid-connect).
  We will get things working with 0.9.0 and then fix our config when we update
  to stable.
* Use `hub.extraConfig` for the config described in [this
  issue](https://github.com/Rhodes-CS-Department/jupyterhub-deployment/issues/15).
  Follow instructions from
  [here](https://zero-to-jupyterhub.readthedocs.io/en/stable/administrator/advanced.html#arbitrary-extra-code-and-configuration-in-jupyterhub-config-py).
* Update `README.md` with info about how logins are handled.
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


