SHELL = bash

ENV ?= dev

env.auto.tfvars:
	@echo 'hcloud_token = "$(HCLOUD_TOKEN)"' >> "$@"

.terraform:
	tofu init

validate: .terraform
	tofu validate

up: .terraform env.auto.tfvars
	tofu apply -auto-approve

down: .terraform env.auto.tfvars
	tofu destroy -auto-approve

clean:
	rm -Rf files/ .terraform/ terraform.tfstate* env.auto.tfvars

deps: clean
	sed -i -e 's|source = ".*"|source = "./.."|' main.tf
	tofu init -upgrade