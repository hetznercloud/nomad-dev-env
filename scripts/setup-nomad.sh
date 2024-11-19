#!/bin/bash
curl -o nomad.zip "https://releases.hashicorp.com/nomad/${1}/nomad_${1}_linux_amd64.zip";
unzip nomad.zip;
mv nomad /usr/local/bin/;
rm LICENSE.txt nomad.zip;
mkdir -p /opt/nomad;
mkdir -p /etc/nomad.d;