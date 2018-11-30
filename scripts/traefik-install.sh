#!/usr/bin/env bash
set -e
set -x

echo Installing Traefik
DASHBOARD=$1
EMAIL=$2
IP=$3

ls -la /root/.helm/repository

helm install --name traefik --namespace kube-system \
  --set rbac.enabled=true \
  --set dashboard.enabled=true,dashboard.domain=$DASHBOARD \
  --set serviceType=NodePort \
  --set externalIP=$IP \
  --set ssl.enabled=true \
  --set acme.enabled=true,acme.logging=true,acme.staging=false \
  --set acme.email=$EMAIL \
  --set acme.persistence.enabled=true \
  --set acme.challengeType=http-01 \
  --set metrics.prometheus.enabled=true \
  stable/traefik

kubectl apply -f /tmp/traefik-pv.yaml

echo Traefik installed
