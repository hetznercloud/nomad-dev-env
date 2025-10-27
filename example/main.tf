module "dev" {
  source = "github.com/hetznercloud/nomad-dev-env?ref=v0.2.1" # x-releaser-pleaser-version

  hcloud_token = var.hcloud_token
}
