resource "terraform_data" "certificates" {
  provisioner "local-exec" {
    command = "bash ${abspath("${path.module}/scripts/generate-tls-certs.sh")} ${abspath("${path.root}/files/")} ${hcloud_server.control.ipv4_address}"
  }
}

data "external" "consul_keygen" {
  program = ["bash", abspath("${path.module}/scripts/generate-consul-key.sh")]
}

# Push files to control and worker

resource "terraform_data" "prepare-control" {
  depends_on = [terraform_data.certificates]

  triggers_replace = [hcloud_server.control.id]

  connection {
    host        = hcloud_server.control.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /certs /etc/systemd/resolved.conf.d /etc/docker /etc/nomad.d /etc/consul.d"]
  }

  provisioner "file" {
    source      = abspath("${path.module}/nomad.service")
    destination = "/etc/systemd/system/nomad.service"
  }

  provisioner "file" {
    source      = abspath("${path.module}/consul.service")
    destination = "/etc/systemd/system/consul.service"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/nomad-agent-ca.pem")
    destination = "/certs/nomad-agent-ca.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/global-server-nomad.pem")
    destination = "/certs/global-server-nomad.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/global-server-nomad-key.pem")
    destination = "/certs/global-server-nomad-key.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/consul-agent-ca.pem")
    destination = "/certs/consul-agent-ca.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/dc1-server-consul-0.pem")
    destination = "/certs/dc1-server-consul-0.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/dc1-server-consul-0-key.pem")
    destination = "/certs/dc1-server-consul-0-key.pem"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/setup-node.sh")
    destination = "./setup-node.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/consul.conf")
    destination = "/etc/systemd/resolved.conf.d/consul.conf"
  }

  provisioner "file" {
    source      = abspath("${path.module}/docker-daemon.json")
    destination = "/etc/docker/daemon.json"
  }

  provisioner "file" {
    content = templatefile(abspath("${path.module}/templates/nomad-control.hcl.tftpl"), {
      ipv4_addr = hcloud_server.control.ipv4_address
    })
    destination = "/etc/nomad.d/nomad.hcl"
  }

  provisioner "file" {
    content = templatefile(abspath("${path.module}/templates/consul-control.hcl.tftpl"), {
      bind_ipv4             = hcloud_server.control.ipv4_address
      consul_encryption_key = data.external.consul_keygen.result["result"]
    })
    destination = "/etc/consul.d/consul.hcl"
  }

  provisioner "file" {
    content = templatefile(abspath("${path.module}/templates/consul-server.hcl.tftpl"), {
      advertise_ipv4 = hcloud_server.control.ipv4_address
    })
    destination = "/etc/consul.d/server.hcl"
  }
}

resource "terraform_data" "prepare-worker" {
  depends_on = [terraform_data.certificates]
  for_each   = { for idx, worker in hcloud_server.worker : idx => worker }

  triggers_replace = [each.value.id, hcloud_server.control.id]

  connection {
    host        = each.value.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /certs /etc/systemd/resolved.conf.d /etc/docker /etc/nomad.d /etc/consul.d"]
  }

  provisioner "file" {
    source      = abspath("${path.module}/nomad.service")
    destination = "/etc/systemd/system/nomad.service"
  }

  provisioner "file" {
    source      = abspath("${path.module}/consul.service")
    destination = "/etc/systemd/system/consul.service"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/nomad-agent-ca.pem")
    destination = "/certs/nomad-agent-ca.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/global-client-nomad.pem")
    destination = "/certs/global-client-nomad.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/global-client-nomad-key.pem")
    destination = "/certs/global-client-nomad-key.pem"
  }

  provisioner "file" {
    source      = abspath("${path.root}/files/consul-agent-ca.pem")
    destination = "/certs/consul-agent-ca.pem"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/setup-node.sh")
    destination = "./setup-node.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/consul.conf")
    destination = "/etc/systemd/resolved.conf.d/consul.conf"
  }

  provisioner "file" {
    source      = abspath("${path.module}/docker-daemon.json")
    destination = "/etc/docker/daemon.json"
  }

  provisioner "file" {
    content = templatefile(abspath("${path.module}/templates/nomad-worker.hcl.tftpl"), {
      control_ipv4 = hcloud_server.control.ipv4_address
    })
    destination = "/etc/nomad.d/nomad.hcl"
  }

  provisioner "file" {
    content = templatefile(abspath("${path.module}/templates/consul-worker.hcl.tftpl"), {
      consul_encryption_key = data.external.consul_keygen.result["result"]
      bind_ipv4             = each.value.ipv4_address
      control_ipv4          = hcloud_server.control.ipv4_address
    })
    destination = "/etc/consul.d/consul.hcl"
  }
}

resource "terraform_data" "setup-control" {
  depends_on = [terraform_data.prepare-control]

  triggers_replace = [hcloud_server.control.id]

  connection {
    host        = hcloud_server.control.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = [
      "bash ./setup-node.sh ${var.consul_version} ${var.nomad_version}",
    ]
  }
}

# Setup docker, consul and nomad

resource "terraform_data" "setup-worker" {
  depends_on = [terraform_data.prepare-worker]
  for_each   = { for idx, worker in hcloud_server.worker : idx => worker }

  triggers_replace = [each.value.id, hcloud_server.control.id]

  connection {
    host        = each.value.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = [
      "bash ./setup-node.sh ${var.consul_version} ${var.nomad_version}",
    ]
  }
}

resource "terraform_data" "nomad_resources" {
  depends_on = [terraform_data.setup-control, terraform_data.setup-worker]

  connection {
    host        = hcloud_server.control.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "file" {
    source      = abspath("${path.module}/docker-registry.hcl")
    destination = "docker-registry.hcl"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "export NOMAD_ADDR='https://localhost:4646'",
      "export NOMAD_CACERT='/certs/nomad-agent-ca.pem'",
      "export NOMAD_CLIENT_CERT='/certs/global-server-nomad.pem'",
      "export NOMAD_CLIENT_KEY='/certs/global-server-nomad-key.pem'",
      // wait for nomad to be up; does not properly work with systemd
      "while ! nomad server members > /dev/null; do sleep 1; done",
      "nomad job run docker-registry.hcl > /dev/null",
      "nomad var put secrets/hcloud hcloud_token=${var.hcloud_token}"
    ]
  }
}

# Export Files

resource "local_file" "environment" {
  content = templatefile(abspath("${path.module}/templates/env.sh.tftpl"), {
    control_ipv4      = hcloud_server.control.ipv4_address
    nomad_cacert      = abspath("${path.root}/files/nomad-agent-ca.pem")
    nomad_client_cert = abspath("${path.root}/files/global-cli-nomad.pem")
    nomad_client_key  = abspath("${path.root}/files/global-cli-nomad-key.pem")
  })
  filename = abspath("${path.root}/files/env.sh")
}

resource "local_file" "registry_port_forward" {
  content = templatefile(abspath("${path.module}/templates/registry-port-forward.sh.tftpl"), {
    ssh_id       = abspath("${path.root}/files/id_ed25519")
    control_ipv4 = hcloud_server.control.ipv4_address
  })
  filename        = abspath("${path.root}/files/registry-port-forward.sh")
  file_permission = "0755"
}

# Cleanup Files

resource "terraform_data" "cleanup" {
  provisioner "local-exec" {
    when    = destroy
    command = "rm -r ${abspath("${path.root}/files/")}"
  }
}
