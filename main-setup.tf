resource "terraform_data" "make_files_dir" {
  provisioner "local-exec" {
    command = "mkdir -p  ${abspath("${path.root}/files/")}"
  }
}

resource "terraform_data" "certificates" {
  provisioner "local-exec" {
    command = "bash ${abspath("${path.module}/scripts/generate-tls-certs.sh")} ${abspath("${path.root}/files/")} ${hcloud_server.control.ipv4_address}"
  }
}

data "external" "consul_keygen" {
  program = ["bash", abspath("${path.module}/scripts/generate-consul-key.sh")]
}

resource "terraform_data" "setup-control" {
  depends_on = [terraform_data.certificates]

  triggers_replace = [hcloud_server.control.id]

  connection {
    host        = hcloud_server.control.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /certs /etc/systemd/resolved.conf.d /etc/docker"]
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
    source      = abspath("${path.module}/scripts/setup-docker.sh")
    destination = "./setup-docker.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/setup-nomad.sh")
    destination = "./setup-nomad.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/setup-consul.sh")
    destination = "./setup-consul.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/install-cni-plugin.sh")
    destination = "./install-cni-plugin.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/consul.conf")
    destination = "/etc/systemd/resolved.conf.d/consul.conf"
  }

  provisioner "file" {
    source      = abspath("${path.module}/docker-daemon.json")
    destination = "/etc/docker/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -eu -o pipefail",
      "DEBIAN_FRONTEND=noninteractive apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq -y unzip openssl ca-certificates curl",
      "bash ./setup-docker.sh",
      "bash ./setup-consul.sh ${var.consul_version}",
      "bash ./setup-nomad.sh ${var.nomad_version}",
      "bash ./install-cni-plugin.sh ${var.cni_plugin_version}"
    ]
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

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "systemctl enable --now consul",
      "systemctl enable --now nomad",
      "systemctl restart systemd-resolved.service"
    ]
  }
}

resource "terraform_data" "setup-worker" {
  depends_on = [terraform_data.setup-control, terraform_data.certificates]
  for_each   = { for idx, worker in hcloud_server.worker : idx => worker }

  triggers_replace = [each.value.id, hcloud_server.control.id]

  connection {
    host        = each.value.ipv4_address
    private_key = tls_private_key.ssh.private_key_openssh
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /certs /etc/systemd/resolved.conf.d /etc/docker"]
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
    source      = abspath("${path.module}/scripts/setup-docker.sh")
    destination = "./setup-docker.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/setup-nomad.sh")
    destination = "./setup-nomad.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/setup-consul.sh")
    destination = "./setup-consul.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/scripts/install-cni-plugin.sh")
    destination = "./install-cni-plugin.sh"
  }

  provisioner "file" {
    source      = abspath("${path.module}/consul.conf")
    destination = "/etc/systemd/resolved.conf.d/consul.conf"
  }

  provisioner "file" {
    source      = abspath("${path.module}/docker-daemon.json")
    destination = "/etc/docker/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "DEBIAN_FRONTEND=noninteractive apt-get update -qq",
      "DEBIAN_FRONTEND=noninteractive apt-get install -qq -y unzip openssl ca-certificates curl",
      "bash ./setup-docker.sh",
      "bash ./setup-consul.sh ${var.consul_version}",
      "bash ./setup-nomad.sh ${var.nomad_version}",
      "bash ./install-cni-plugin.sh ${var.cni_plugin_version}"
    ]
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

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "set -euo pipefail",
      "systemctl enable --now consul",
      "systemctl enable --now nomad",
      "systemctl restart systemd-resolved.service"
    ]
  }
}

resource "terraform_data" "docker_registry" {
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
      "nomad job run docker-registry.hcl"
    ]
  }
}

# Export Files

resource "terraform_data" "environment" {
  depends_on = [hcloud_server.control]

  provisioner "local-exec" {
    command = "sed 's/REPLACE_IPV4/${hcloud_server.control.ipv4_address}/' ${abspath("${path.module}/templates/env.sh.tftpl")} > ${abspath("${path.root}/files/env.sh")}"
  }

  provisioner "local-exec" {
    command = "sed -i 's/REPLACE_CA_PATH/${replace(abspath("${path.root}/files/nomad-agent-ca.pem"), "/", "\\/")}/' ${abspath("${path.root}/files/env.sh")}"
  }

  provisioner "local-exec" {
    command = "sed -i 's/REPLACE_CLIENT_CERT_PATH/${replace(abspath("${path.root}/files/global-cli-nomad.pem"), "/", "\\/")}/' ${abspath("${path.root}/files/env.sh")}"
  }

  provisioner "local-exec" {
    command = "sed -i 's/REPLACE_CLIENT_KEY_PATH/${replace(abspath("${path.root}/files/global-cli-nomad-key.pem"), "/", "\\/")}/' ${abspath("${path.root}/files/env.sh")}"
  }
}

resource "local_file" "registry_port_forward" {
  content = templatefile(abspath("${path.module}/templates/registry-port-forward.sh.tftpl"), {
    ssh_id            = abspath("${path.root}/files/id_ed25519")
    control_ipv4      = hcloud_server.control.ipv4_address
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