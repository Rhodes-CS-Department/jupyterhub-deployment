# TODO

- expose grafana externally
- set up grafana + prometheus persistence on PVs
  - [grafana
    configs](https://github.com/grafana/helm-charts/blob/main/charts/grafana/README.md) 
  - prometheus is already aneabled; increase volume size
    ```
    [lang@eschaton ~/dsrc/jupyter]$ kubectl -n prometheus get pvc
    NAME                      STATUS   VOLUME
    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    prometheus-alertmanager   Bound    pvc-3f75416a-4a1d-4c2e-8342-b162c0c30674
    2Gi        RWO            standard       57m
    prometheus-server         Bound    pvc-52fdffc6-87f3-41b7-9eaf-4786d14cc530
    8Gi        RWO            standard       57m
    ```

#### Viewing config data in helm

```
helm show values [chart name]
```

# Enable scraping

By default the `/metrics` endpoints in JupyterHub require authentication;
disable with `authenticate_prometheus: false`.

# Installing Prometheus

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
# install prometheus
./scripts/prometheus_upgrade.sh
# connect to prometheus
export POD_NAME=$(kubectl get pods --namespace prometheus -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace prometheus port-forward $POD_NAME 9090
```

# Installing Grafana

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
./scripts/grafana_upgrade.sh
# get default password
kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
# port-forward server to localhost
export POD_NAME=$(kubectl get pods --namespace grafana -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o
jsonpath="{.items[0].metadata.name}")
kubectl --namespace grafana port-forward $POD_NAME 3000

```
