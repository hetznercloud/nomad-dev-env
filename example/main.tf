module "dev" {
  source = "github.com/hetznercloud/nomad-dev-env?ref=v0.0.0" # x-releaser-pleaser-version

  hcloud_token = var.hcloud_token
}
