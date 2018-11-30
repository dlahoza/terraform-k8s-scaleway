# terraform-k8s-scaleway

Kubernetes Terraform installer for Scaleway cloud AMD64

### Initial setup

Clone the repository and install the dependencies:

```bash
$ git clone https://github.com/DLag/terraform-k8s-scaleway.git
$ cd terraform-k8s-scaleway
$ terraform init
```

Note that you'll need Terraform v0.10 or newer to run this project.

Before running the project you'll have to create an access token for Terraform to connect to the Scaleway API

Now retrieve the `<ORGANIZATION_ID>` using your `<ACCESS-TOKEN>` from `/organizations` API endpoint:

```bash
$ curl https://account.scaleway.com/organizations -H "X-Auth-Token: <ACCESS-TOKEN>"
```

Sample output (excerpt with organization ID):
```bash
"organizations": [{"id": "xxxxxxxxxxxxx", "name": "Organization Name"}],
```

Using the token and your organization ID, create two environment variables:

```bash
$ export SCALEWAY_ORGANIZATION="<ORGANIZATION_ID>"
$ export SCALEWAY_TOKEN="<ACCESS-TOKEN>"
```

Or if you have already configured scw utility just run this:

```bash
export SCALEWAY_ORGANIZATION="$(cut -d'"' -f4 < ~/.scwrc)"
export SCALEWAY_TOKEN="$(cut -d'"' -f8 < ~/.scwrc)"
```

To configure your cluster, you'll need to have `jq` installed on your computer.

### Usage

Create an AMD64 bare-metal Kubernetes cluster with one master and a node:

```bash
$ terraform workspace new amd64

$ terraform apply \
 -var region=ams1 \
 -var arch=x86_64 \
 -var server_type=START1-S \
 -var nodes=1 \
 -var server_type_node=START1-S \
 -var weave_passwd=some_weave_pass \
 -var traefik_dashboard_domain=traefik.example.com \
 -var traefik_acme_email=admin@example.com \
 -var grafana_domain=grafana.example.com
 -auto-approve
```

This will do the following:

* reserves public IPs for each server
* provisions three bare-metal servers with Ubuntu 16.04.1 LTS (the size of the `master` and the `node` may be different but must remain in the same type of architecture)
* connects to the master server via SSH and installs Docker CE and kubeadm apt packages
* runs kubeadm init on the master server and configures kubectl
* downloads the kubectl admin config file on your local machine and replaces the private IP with the public one
* creates a Kubernetes secret with the Weave Net password
* installs Weave Net with encrypted overlay
* starts the nodes in parallel and installs Docker CE and kubeadm
* joins the nodes in the cluster using the kubeadm token obtained from the master
* installs cluster add-ons (Kubernetes dashboard)
* installs Traefik Ingress and Prometheus

Scale up by increasing the number of nodes:

```bash
$ terraform apply \
 -var nodes=3
```

Tear down the whole infrastructure with:

```bash
terraform destroy -force
```

### Remote control

After applying the Terraform plan you'll see several output variables like the master public IP,
the kubeadmn join command and the current workspace admin config.

In order to run `kubectl` commands against the Scaleway cluster you can use the `kubectl_config` output variable:

Check if Kubernetes works

```bash
$ kubectl --kubeconfig ./$(terraform output kubectl_config) \
  get pods

NAME           CPU(cores)   CPU%      MEMORY(bytes)   MEMORY%
arm-master-1   655m         16%       873Mi           45%
arm-node-1     147m         3%        618Mi           32%
arm-node-2     101m         2%        584Mi           30%
```

The `kubectl` config file format is `<WORKSPACE>.conf` as in `arm.conf` or `amd64.conf`.

In order to access the dashboard you can use port forward:

```bash
$ kubectl --kubeconfig ./$(terraform output kubectl_config) \
  -n kube-system port-forward deployment/kubernetes-dashboard 8888:9090
```

Now you can access the dashboard on your computer at `http://localhost:8888`.

![Overview](https://github.com/DLag/terraform-k8s-scaleway/blob/master/screens/dash-overview.png)

![Nodes](https://github.com/DLag/terraform-k8s-scaleway//blob/master/screens/dash-nodes.png)

### Expose services outside the cluster

Since we're running on bare-metal and Scaleway doesn't offer a load balancer, the easiest way to expose
applications outside of Kubernetes is using a NodePort service.

Let's deploy the [podinfo](https://github.com/stefanprodan/k8s-podinfo) app in the default namespace.
Podinfo has a multi-arch Docker image and it will work on arm, arm64 or amd64.

Create the podinfo nodeport service:

```bash
$ kubectl --kubeconfig ./$(terraform output kubectl_config) \
  apply -f https://raw.githubusercontent.com/stefanprodan/k8s-podinfo/7a8506e60fca086572f16de57f87bf5430e2df48/deploy/podinfo-svc-nodeport.yaml
 
service "podinfo-nodeport" created
```

Create the podinfo deployment:

```bash
$ kubectl --kubeconfig ./$(terraform output kubectl_config) \
  apply -f https://raw.githubusercontent.com/stefanprodan/k8s-podinfo/7a8506e60fca086572f16de57f87bf5430e2df48/deploy/podinfo-dep.yaml

deployment "podinfo" created
```

Inspect the podinfo service to obtain the port number:

```bash
$ kubectl --kubeconfig ./$(terraform output kubectl_config) \
  get svc --selector=app=podinfo

NAME               TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
podinfo-nodeport   NodePort   10.104.132.14   <none>        9898:31190/TCP   3m
```

You can access podinfo at `http://<MASTER_PUBLIC_IP>:31190` or using curl:

```bash
$ curl http://$(terraform output k8s_master_public_ip):31190

runtime:
  arch: arm
  max_procs: "4"
  num_cpu: "4"
  num_goroutine: "12"
  os: linux
  version: go1.9.2
labels:
  app: podinfo
  pod-template-hash: "1847780700"
annotations:
  kubernetes.io/config.seen: 2018-01-08T00:39:45.580597397Z
  kubernetes.io/config.source: api
environment:
  HOME: /root
  HOSTNAME: podinfo-5d8ccd4c44-zrczc
  KUBERNETES_PORT: tcp://10.96.0.1:443
  KUBERNETES_PORT_443_TCP: tcp://10.96.0.1:443
  KUBERNETES_PORT_443_TCP_ADDR: 10.96.0.1
  KUBERNETES_PORT_443_TCP_PORT: "443"
  KUBERNETES_PORT_443_TCP_PROTO: tcp
  KUBERNETES_SERVICE_HOST: 10.96.0.1
  KUBERNETES_SERVICE_PORT: "443"
  KUBERNETES_SERVICE_PORT_HTTPS: "443"
  PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
externalIP:
  IPv4: 163.172.139.112
```
