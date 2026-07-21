.PHONY: build run clean help

IMAGE_NAME ?= keycloak-local
BUILD_ENV ?= LOCAL # Default to LOCAL for Zscaler certificate inclusion

# Container engine detection: prefer Docker, fall back to Podman
CONTAINER_ENGINE ?= $(shell command -v docker >/dev/null 2>&1 && echo docker || echo podman)

build:
	@echo "Building $(CONTAINER_ENGINE) image '$(IMAGE_NAME)' with BUILD_ENV=$(BUILD_ENV)..."
	$(CONTAINER_ENGINE) build --no-cache --build-arg BUILD_ENV=$(BUILD_ENV) -t $(IMAGE_NAME) .
	@echo "$(CONTAINER_ENGINE) image build complete."

run:
	@echo "Running Keycloak $(CONTAINER_ENGINE) container from image '$(IMAGE_NAME)'..."
	@echo "Admin console will be available at http://localhost:8080"
	@echo "Default admin credentials: username=admin, password=admin"
	$(CONTAINER_ENGINE) run -p 8080:8080 -p 8443:8443 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin $(IMAGE_NAME)
	@echo "Keycloak container started."

clean:
	@echo "Attempting to stop and remove any running containers based on '$(IMAGE_NAME)'..."
	-$(CONTAINER_ENGINE) stop $(shell $(CONTAINER_ENGINE) ps -q --filter ancestor=$(IMAGE_NAME)) || true
	-$(CONTAINER_ENGINE) rm $(shell $(CONTAINER_ENGINE) ps -aq --filter ancestor=$(IMAGE_NAME)) || true
	@echo "Removing $(CONTAINER_ENGINE) image '$(IMAGE_NAME)'..."
	-$(CONTAINER_ENGINE) rmi $(IMAGE_NAME) || true
	@echo "Cleanup complete."

help:
	@echo "Makefile for Keycloak local development:"
	@echo "  build      - Build the container image for Keycloak with local extensions (Docker or Podman)."
	@echo "               Use 'make build BUILD_ENV=production' to skip Zscaler cert inclusion."
	@echo "  run        - Run the Keycloak container (admin:admin)."
	@echo "  clean      - Stop and remove running containers and delete the built image."
	@echo "  help       - Display this help message."
