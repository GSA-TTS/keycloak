# Stage 1: Build the login.gov extension
FROM maven:3.9-eclipse-temurin-17 AS builder

# Copy the entire project source
# This allows Maven to resolve all local modules and parent POMs.
# Ensure your .dockerignore file is set up to exclude unnecessary files (e.g., .git, host target folders).
COPY . /usr/src/keycloak-project/
WORKDIR /usr/src/keycloak-project/

# Initialize and update submodules, unless their content is already present
# in the build context (e.g. when this repo is checked out as a git submodule
# itself, .git is a gitlink pointing outside the build context and can't be
# used to re-resolve submodules here — but the host will have already
# checked them out, so there's nothing to do).
RUN if [ -f keycloak-login.gov-integration/pom.xml ] && [ -f extensions/keycloak-api-key-demo/api-key-module/pom.xml ]; then \
		echo "Submodule content already present, skipping git submodule update"; \
	else \
		git submodule update --init --recursive; \
	fi

# Copy the Maven settings file to the working directory.
COPY maven-settings.xml /usr/src/keycloak-project/maven-settings.xml

# Set the working directory to the root of the Keycloak project.
WORKDIR /usr/src/keycloak-project/
# Run Maven to clean and package the project.
# The clean command removes any previously compiled files, ensuring a fresh build.



# Build the login.gov extension module.
# The -pl flag specifies the module to build.
# The -am flag (alsomake) ensures that any local Maven modules it depends on are also built.
# -DskipTests is used to speed up the build process by skipping tests.
# The cache mount persists ~/.m2 across builds (including --no-cache rebuilds),
# so the large reactor's dependencies aren't re-downloaded every time.
RUN --mount=type=cache,target=/root/.m2 \
    mvn --settings maven-settings.xml clean package -pl keycloak-login.gov-integration -am -DskipTests

# List the contents of the target directory for login.gov integration for debugging
RUN ls -l /usr/src/keycloak-project/keycloak-login.gov-integration/target/

# Build other extensions
RUN --mount=type=cache,target=/root/.m2 \
    mvn --settings maven-settings.xml clean package -f extensions/keycloak-api-key-demo/api-key-module -DskipTests
RUN ls -l /usr/src/keycloak-project/extensions/keycloak-api-key-demo/api-key-module/target/deploy/
RUN --mount=type=cache,target=/root/.m2 \
    mvn --settings maven-settings.xml clean package -f extensions/keycloak-api-key-demo/dashboard-service -DskipTests
RUN ls -l /usr/src/keycloak-project/extensions/keycloak-api-key-demo/dashboard-service/target/

# Stage 2: Prepare the Keycloak runtime
# Use the official Keycloak image as the base.
# Note: If you encounter TLS errors pulling this image, it's an environment issue
# with your Docker setup's trust store for quay.io.
FROM quay.io/keycloak/keycloak:26.2.3

# Copy the Login.gov extension JAR built in the 'builder' stage.
# This copies the JAR from the target directory of the keycloak-login.gov-integration module
# (e.g., login_gov-VERSION.jar) into the providers directory of the Keycloak installation.
# Using a wildcard (*) for the version part of the JAR name for flexibility.
COPY --from=builder /usr/src/keycloak-project/keycloak-login.gov-integration/target/keycloak-login.gov-integration-*.jar /opt/keycloak/providers/
COPY --from=builder /usr/src/keycloak-project/extensions/keycloak-api-key-demo/api-key-module/target/deploy/api-key-module-*.jar /opt/keycloak/providers/
COPY --from=builder /usr/src/keycloak-project/extensions/keycloak-api-key-demo/dashboard-service/target/dashboard-service-*.jar /opt/keycloak/providers/

# Copy the custom usai theme directly from source. This directory is already
# laid out the way Keycloak expects at runtime (login/*.ftl, resources/,
# messages/, theme.properties) — no Maven build needed. The themes module's
# own build (via `mvn package -f themes`) also builds Keycloak's upstream
# admin/account console themes, which pull in keycloak-admin-ui/account-ui/
# themes-vendor artifacts that only exist inside a full Keycloak monorepo
# build, so it's not viable to build in isolation here.
COPY --from=builder /usr/src/keycloak-project/themes/src/main/resources/theme/usai/ /opt/keycloak/themes/usai/

# Standard Keycloak environment variables (retained from original Dockerfile)
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_HOSTNAME=localhost
# kc.sh build persists build-time options (including features) into the
# optimized image. If the runtime KC_FEATURES (set in docker-compose.yml)
# doesn't match what was baked in here, `kc.sh start --optimized` fails at
# startup rather than warning and continuing. Keep this list in sync with
# docker-compose.yml's KC_FEATURES.
ENV KC_FEATURES=token-exchange,admin-fine-grained-authz,admin-api,admin,authorization,ciba,client-policies,device-flow,impersonation,kerberos,login,organization,par,persistent-user-sessions,token-exchange-standard,user-event-metrics,client-secret-rotation

WORKDIR /opt/keycloak

# Run Keycloak's build command. This step is crucial as it optimizes Keycloak
# and incorporates any new providers (like our login_gov extension) into the server.
# This command should be run after new providers are added.
RUN /opt/keycloak/bin/kc.sh build

# Define the entrypoint and default command for running Keycloak (retained from original Dockerfile)
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
