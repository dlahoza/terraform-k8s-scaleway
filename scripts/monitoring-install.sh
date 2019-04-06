#!/usr/bin/env bash

set -e

ARCH=$1
GRAFANA_DOMAIN=$2
GRAFANA_PASSWORD=$3

echo Installing Kubernetes Dashboard...
if [ "$ARCH" == "arm" ]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/alternative/kubernetes-dashboard-arm.yaml;
elif [ "$ARCH" == "x86_64" ]; then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml;
fi
kubectl apply -f /tmp/dashboard-rbac.yaml
echo Kubernetes Dashboard installed.

echo Installing Kube-Prometheus...
kubectl create -f /tmp/kube-prometheus/ || true

# It can take a few seconds for the above 'create manifests' command to fully create the following resources, so verify the resources are ready before proceeding.
until kubectl get customresourcedefinitions servicemonitors.monitoring.coreos.com ; do date; sleep 1; echo ""; done
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

kubectl create -f /tmp/kube-prometheus/ 2>/dev/null || true  # This command sometimes may need to be done twice (to workaround a race condition).

sed -i "s/grafana.example.com/$GRAFANA_DOMAIN/" /tmp/monitoring-expose.yml
sed -i "s/grafana_password/$GRAFANA_PASSWORD/" /tmp/monitoring-expose.yml
kubectl apply -f /tmp/monitoring-expose.yml

echo Kube-Prometheus installed.

echo Installing metrics-server
kubectl create -f /tmp/metrics-server/ || true
echo metrics-server installed.

