#!/bin/bash

set -eu -o pipefail

curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v${1}/cni-plugins-linux-amd64-v${1}".tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf cni-plugins.tgz

modprobe bridge
