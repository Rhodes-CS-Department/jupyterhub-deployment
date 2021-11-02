# Viewing config data in helm

```
helm show values [chart name]
```

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
