#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Prerequisites

apt-get update -qq
apt-get install -qq -y unzip openssl ca-certificates curl

# Docker

# We use the hcloud docker-ce image and therefore need to restart docker after
# modifying the /etc/docker/daemon.json
systemctl restart docker

# Consul

curl -o consul.zip "https://releases.hashicorp.com/consul/${1}/consul_${1}_linux_amd64.zip"
unzip consul.zip
mv consul /usr/local/bin/
rm LICENSE.txt consul.zip
mkdir -p /opt/consul

systemctl enable --now consul

# Nomad

curl -o nomad.zip "https://releases.hashicorp.com/nomad/${2}/nomad_${2}_linux_amd64.zip"
unzip nomad.zip
mv nomad /usr/local/bin/
rm LICENSE.txt nomad.zip
mkdir -p /opt/nomad

systemctl enable --now nomad

# Restart after adding consul DNS server
systemctl restart systemd-resolved.service
