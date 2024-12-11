# Nomad Dev Env

This repository provides an easy way to setup a simple Nomad cluster with self-signed certificates on the Hetzner cloud.

> [!WARNING]
> This project is not an official Hetzner Cloud Integration and is intended to be used internally. There is no backwards-compatibility promise.

## Requirements

- [Nomad](https://developer.hashicorp.com/nomad/docs/install)
- [OpenTofu](https://opentofu.org/docs/intro/install/)

## Usage

1. Set the `HCLOUD_TOKEN` environment variable

> [!WARNING]
> The development environment runs on Hetzner Cloud servers, which will induce costs.

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

⚠️ Do not forget to clean up the development cluster once you are finished:

```sh
make -C example down
```
