#!/usr/bin/env bash
set -e
wait_pods () {
	sleep 2
	while [ `kubectl get pods --namespace=kube-system | grep -v "NAME" | grep -v Running | wc -l` -gt "0" ]; do echo Waiting for pods to start...; sleep 2; done
}
wait_pods
wget -O- https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash
helm init
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
wait_pods
wait_pods
set +e
helm version > /dev/null || CODE=$? && while [ $CODE -gt 0 ] ; do sleep 2; CODE=0; helm version > /dev/null || CODE=$?; done
sleep 10
echo Helm has been deployed
