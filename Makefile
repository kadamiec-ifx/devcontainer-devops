# Makefile for building a Docker image
# Usage from devcontainer in docker
# make aws-shell MOUNT_PATH=$(echo "$PWD/.."|sed 's/workspaces/home/g')

# Variables

# Targets
.PHONY: build-ubuntu


# IMAGE_NAME := devcont
# DOCKERFILE := Dockerfile
MOUNT_PATH ?= $$(echo "$$PWD/.."|sed 's/^\/workspaces/\/home/g')

ubuntu:
	$(eval DISTRO := ubuntu)

alpine:
	$(eval DISTRO := alpine)

env:
	$(eval IMAGE_NAME := ${DISTRO}-devcont)
	$(eval DOCKERFILE := ./dc-${DISTRO}/Dockerfile.${DISTRO})
	@echo "Dockerfile: ${DOCKERFILE} | Target Image Name: ${IMAGE_NAME}"

build: env
	docker build -f ${DOCKERFILE} -t ${IMAGE_NAME} .

run: env
	docker run -it --rm -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} -v "${MOUNT_PATH}":/workdir ${IMAGE_NAME} /bin/bash

run-dockermount: env
	docker run -it --rm -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} -e AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} -v "${MOUNT_PATH}":/workdir -v /var/run/docker.sock:/var/run/docker.sock ${IMAGE_NAME} /bin/bash

# Ubuntu shortcuts
build-ubuntu: ubuntu env build 
run-ubuntu: ubuntu env run
run-ubuntu-dockermount: ubuntu env run-dockermount

# Alpine shortcuts
build-alpine: alpine env build 
run-alpine: alpine env run
run-alpine-dockermount: alpine env run-dockermount


init-dotfiles:
	mkdir -p ~/.mount/dotfiles_priv/.aws
	mkdir -p ~/.mount/dotfiles_priv/.terraform.d
	mkdir -p ~/.mount/dotfiles_priv/.kube
	mkdir -p ~/.mount/dotfiles_priv/gopass_store
	touch ~/.mount/dotfiles_priv/.zsh_history
	touch ~/.mount/dotfiles_priv/.bash_history
	# stow -d ~/.mount --adopt dotfiles_priv

