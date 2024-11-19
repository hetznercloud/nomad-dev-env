provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "ssh_private" {
  content = tls_private_key.ssh.private_key_openssh
  filename = "${abspath("${path.root}/files/id_ed25519")}"
}

resource "local_sensitive_file" "ssh_public" {
  content = tls_private_key.ssh.public_key_openssh
  filename = "${abspath("${path.root}/files/id_ed25519.pub")}"
}

resource "hcloud_ssh_key" "tofu" {
  name = "tofu"
  public_key = tls_private_key.ssh.public_key_openssh
}

resource "hcloud_server" "control" {
  name = "nomad-control"
  image = "ubuntu-24.04"
  location = "hel1"
  server_type = var.server_type
  ssh_keys = [ hcloud_ssh_key.tofu.name ]

  connection {
    host = self.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = [ "cloud-init status --wait || test $? -eq 2" ]
  }
}

resource "hcloud_server" "worker" {
  count = var.worker_count
  name = "nomad-worker-${count.index}"
  image = "ubuntu-24.04"
  location = "hel1"
  server_type = var.server_type
  ssh_keys = [ hcloud_ssh_key.tofu.name ]

  connection {
    host = self.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = [ "cloud-init status --wait || test $? -eq 2" ]
  }
}
