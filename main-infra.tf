provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private" {
  content  = tls_private_key.ssh.private_key_openssh
  filename = abspath("${path.root}/files/id_ed25519")
}

resource "local_sensitive_file" "ssh_public" {
  content  = tls_private_key.ssh.public_key_openssh
  filename = abspath("${path.root}/files/id_ed25519.pub")
}

resource "hcloud_ssh_key" "tofu" {
  name       = "tofu"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Network

resource "hcloud_network" "cluster" {
  name     = "cluster"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "cluster" {
  network_id   = hcloud_network.cluster.id
  network_zone = "eu-central"
  type         = "cloud"
  ip_range     = "10.0.0.0/24"
}

resource "hcloud_server" "control" {
  name        = "nomad-control"
  image       = "ubuntu-24.04"
  location    = "hel1"
  server_type = var.server_type
  ssh_keys    = [hcloud_ssh_key.tofu.name]

  connection {
    host        = self.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait || test $? -eq 2"]
  }
}

resource "hcloud_server_network" "control" {
  server_id = hcloud_server.control.id
  subnet_id = hcloud_network_subnet.cluster.id
}

resource "hcloud_server" "worker" {
  count       = var.worker_count
  name        = "nomad-worker-${count.index}"
  image       = "ubuntu-24.04"
  location    = "hel1"
  server_type = var.server_type
  ssh_keys    = [hcloud_ssh_key.tofu.name]

  connection {
    host        = self.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait || test $? -eq 2"]
  }
}

resource "hcloud_server_network" "worker" {
  count = var.worker_count

  server_id = hcloud_server.worker[count.index].id
  subnet_id = hcloud_network_subnet.cluster.id
}
