variable "name" {
  description = "Name of the environment"
  type        = string
  default     = "dev"
}

variable "consul_version" {
  description = "Consul version used for the environment"
  default     = "1.22.4" # renovate: datasource=github-releases depName=hashicorp/consul extractVersion=v(?<version>.+)
}

variable "nomad_version" {
  description = "Nomad version used for the environment"
  default     = "1.11.2" # renovate: datasource=github-releases depName=hashicorp/nomad extractVersion=v(?<version>.+)
}

variable "worker_count" {
  description = "Number of worker for the environment"
  default     = 1
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "hcloud_server_type" {
  description = "Hetzner Cloud Server Type used for the environment"
  default     = "cpx22"
}

variable "hcloud_labels" {
  description = "Additional labels that are added to all Hetzner Cloud resources"
  type        = map(string)
  default     = {}
}

variable "hcloud_location" {
  description = "Hetzner Cloud Location used for the environment"
  type        = string
  default     = "hel1"
}

variable "hcloud_network_zone" {
  description = "Hetzner Cloud network zone used for the environment"
  type        = string
  default     = "eu-central"
}
