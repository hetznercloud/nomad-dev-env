# Nomad Dev Env

This repository provides an easy way to setup a simple Nomad cluster with self-signed certificates on the Hetzner cloud.

## Requirements

- [Nomad](https://developer.hashicorp.com/nomad/docs/install)
- [OpenTofu](https://opentofu.org/docs/intro/install/)

## Usage

1. Set the `HCLOUD_TOKEN` environment variable

2. Deploy the development cluster:

```bash
make -C example up
```

3. Load the generated configuration to access the development cluster:

```bash
source example/files/env.sh
```

4. Check that the development cluster is healthy:

```bash
nomad node status
```
