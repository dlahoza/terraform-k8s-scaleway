#!/usr/bin/env bash

set -e

DOCKER_VERSION=$1

apt-get update -qq
apt-get install -y -qq software-properties-common apt-transport-https ca-certificates curl git
curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | apt-key add -qq -
echo "deb https://download.docker.com/linux/ubuntu xenial stable" | tee /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq --no-install-recommends docker-ce=${DOCKER_VERSION}
apt-mark hold docker-ce
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

docker version

