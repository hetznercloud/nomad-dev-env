#!/bin/bash

set -eu -o pipefail

echo "{\"result\": \"$(consul keygen)\"}"
