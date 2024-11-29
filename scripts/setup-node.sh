#!/bin/bash

set -euo pipefail

DEBIAN_FRONTEND=noninteractive

# Prerequisites

apt-get update -qq
apt-get install -qq -y unzip openssl ca-certificates curl

# Docker

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io

# Consul

curl -o consul.zip https://releases.hashicorp.com/consul/${1}/consul_${1}_linux_amd64.zip
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