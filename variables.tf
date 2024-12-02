variable "hcloud_token" {
  sensitive = true
}

variable "consul_version" {
  default = "1.20.1"
}

variable "nomad_version" {
  default = "1.9.3"
}

variable "cni_plugin_version" {
  default = "1.5.1"
}

variable "worker_count" {
  default = 1
}

variable "server_type" {
  default = "cx22"
}