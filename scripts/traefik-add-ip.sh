#!/usr/bin/env bash
set -e

IP=$1

kubectl get svc -n kube-system traefik -o json | jq ".spec.externalIPs += [\"$IP\"]" > /tmp/traefik-ip.json
kubectl apply -n kube-system -f /tmp/traefik-ip.json

