# Tell terraform to use the provider and select a version.
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
  }
}
