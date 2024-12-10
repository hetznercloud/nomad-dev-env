module "dev" {
  # source = "github.com/hetznercloud/nomad-dev-env?ref=v0.0.0"
  source = "../"

  hcloud_token = var.hcloud_token
}
