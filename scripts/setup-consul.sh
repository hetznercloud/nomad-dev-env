#!/bin/bash

set -eu -o pipefail

curl -o consul.zip https://releases.hashicorp.com/consul/${1}/consul_${1}_linux_amd64.zip;
unzip consul.zip;
mv consul /usr/local/bin/;
rm LICENSE.txt consul.zip;
mkdir -p /etc/consul.d/;
mkdir -p /opt/consul;