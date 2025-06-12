# Stage 1: Build the login.gov extension
FROM maven:3.9-eclipse-temurin-17 AS builder

# Copy the entire project source
# This allows Maven to resolve all local modules and parent POMs.
# Ensure your .dockerignore file is set up to exclude unnecessary files (e.g., .git, host target folders).
COPY . /usr/src/keycloak-project/
WORKDIR /usr/src/keycloak-project/

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
RUN mvn --settings maven-settings.xml clean package -pl keycloak-login.gov-integration -am -DskipTests

# List the contents of the target directory for login.gov integration for debugging
RUN ls -l /usr/src/keycloak-project/keycloak-login.gov-integration/target/

# Build other extensions
RUN mvn --settings maven-settings.xml clean package -f extensions/keycloak-api-key-demo/api-key-module -DskipTests
RUN ls -l /usr/src/keycloak-project/extensions/keycloak-api-key-demo/api-key-module/target/deploy/
RUN mvn --settings maven-settings.xml clean package -f extensions/keycloak-api-key-demo/dashboard-service -DskipTests
RUN ls -l /usr/src/keycloak-project/extensions/keycloak-api-key-demo/dashboard-service/target/

# Stage 2: Prepare the Keycloak runtime
# Use the official Keycloak image as the base.
# Note: If you encounter TLS errors pulling this image, it's an environment issue
# with your Docker setup's trust store for quay.io.
FROM quay.io/keycloak/keycloak:23.0.6

# Copy the Login.gov extension JAR built in the 'builder' stage.
# This copies the JAR from the target directory of the keycloak-login.gov-integration module
# (e.g., login_gov-VERSION.jar) into the providers directory of the Keycloak installation.
# Using a wildcard (*) for the version part of the JAR name for flexibility.
COPY --from=builder /usr/src/keycloak-project/keycloak-login.gov-integration/target/keycloak-login.gov-integration-*.jar /opt/keycloak/providers/
COPY --from=builder /usr/src/keycloak-project/extensions/keycloak-api-key-demo/api-key-module/target/deploy/api-key-module-*.jar /opt/keycloak/providers/
COPY --from=builder /usr/src/keycloak-project/extensions/keycloak-api-key-demo/dashboard-service/target/dashboard-service-*.jar /opt/keycloak/providers/

# Standard Keycloak environment variables (retained from original Dockerfile)
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_HOSTNAME=localhost

WORKDIR /opt/keycloak

# Run Keycloak's build command. This step is crucial as it optimizes Keycloak
# and incorporates any new providers (like our login_gov extension) into the server.
# This command should be run after new providers are added.
RUN /opt/keycloak/bin/kc.sh build

# Define the entrypoint and default command for running Keycloak (retained from original Dockerfile)
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
