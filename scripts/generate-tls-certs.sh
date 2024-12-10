#!/bin/bash

set -eu -o pipefail

cd "$1"
nomad tls ca create
nomad tls cert create -server -region global -additional-ipaddress "$2"
nomad tls cert create -client
nomad tls cert create -cli

consul tls ca create
consul tls cert create -server -additional-ipaddress "$2"
