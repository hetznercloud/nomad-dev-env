job "docker-registry" {
    type = "service"

    group "registry" {
        count = 1

        network {
            port "registry" {
                static = 5000
                host_network = "private"
            }
        }

        service {
            name = "docker-registry"
            port = "registry"
            provider = "consul"

            check {
                type     = "http"
                name     = "registry_up"
                path     = "/"
                interval = "10s"
                timeout  = "2s"
            }
        }

        task "registry" {
            driver = "docker"

            config {
                image = "registry:2"
                ports = [
                    "registry"
                ]
            }
        }
    }
}
