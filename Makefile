.PHONY: build run clean help

IMAGE_NAME ?= keycloak-local
BUILD_ENV ?= LOCAL # Default to LOCAL for Zscaler certificate inclusion

build:
	@echo "Building Docker image '$(IMAGE_NAME)' with BUILD_ENV=$(BUILD_ENV)..."
	docker build --no-cache --build-arg BUILD_ENV=$(BUILD_ENV) -t $(IMAGE_NAME) .
	@echo "Docker image build complete."

run:
	@echo "Running Keycloak Docker container from image '$(IMAGE_NAME)'..."
	@echo "Admin console will be available at http://localhost:8080"
	@echo "Default admin credentials: username=admin, password=admin"
	docker run -p 8080:8080 -p 8443:8443 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin $(IMAGE_NAME)
	@echo "Keycloak container started."

clean:
	@echo "Attempting to stop and remove any running containers based on '$(IMAGE_NAME)'..."
	-docker stop $(shell docker ps -q --filter ancestor=$(IMAGE_NAME)) || true
	-docker rm $(shell docker ps -aq --filter ancestor=$(IMAGE_NAME)) || true
	@echo "Removing Docker image '$(IMAGE_NAME)'..."
	-docker rmi $(IMAGE_NAME) || true
	@echo "Cleanup complete."

help:
	@echo "Makefile for Keycloak local development:"
	@echo "  build      - Build the Docker image for Keycloak with local extensions."
	@echo "               Use 'make build BUILD_ENV=production' to skip Zscaler cert inclusion."
	@echo "  run        - Run the Keycloak Docker container (admin:admin)."
	@echo "  clean      - Stop and remove running containers and delete the built Docker image."
	@echo "  help       - Display this help message."
