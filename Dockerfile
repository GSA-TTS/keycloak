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
# Build just the Keycloak distribution without running full testsuite
RUN mvn --settings maven-settings.xml clean install -DskipTests -pl quarkus/dist -am

# Build the login.gov extension module
RUN mvn --settings maven-settings.xml clean package -pl keycloak-login.gov-integration -am -DskipTests

# List the contents of the target directory for login.gov integration for debugging
RUN ls -l /usr/src/keycloak-project/keycloak-login.gov-integration/target/

# Build other extensions
RUN mvn --settings maven-settings.xml clean package -f extensions/keycloak-api-key-demo/api-key-module -DskipTests
RUN ls -l /usr/src/keycloak-project/extensions/keycloak-api-key-demo/api-key-module/target/deploy/
RUN mvn --settings maven-settings.xml clean package -f extensions/keycloak-api-key-demo/dashboard-service -DskipTests
RUN ls -l /usr/src/keycloak-project/extensions/keycloak-api-key-demo/dashboard-service/target/

# List the Keycloak distribution for debugging
RUN ls -l /usr/src/keycloak-project/quarkus/dist/target/

# Stage 2: Build Keycloak from source
FROM eclipse-temurin:17-jre

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create keycloak user and group
RUN groupadd -r keycloak && useradd -r -g keycloak keycloak

# Copy the built Keycloak distribution from the builder stage
COPY --from=builder /usr/src/keycloak-project/quarkus/dist/target/keycloak-*.tar.gz /tmp/keycloak.tar.gz

# Extract Keycloak and set up directory structure
RUN cd /opt && \
    tar -xzf /tmp/keycloak.tar.gz && \
    mv keycloak-* keycloak && \
    rm /tmp/keycloak.tar.gz && \
    chown -R keycloak:keycloak /opt/keycloak

# Copy the Login.gov extension JAR and other custom extensions
COPY --from=builder /usr/src/keycloak-project/keycloak-login.gov-integration/target/keycloak-login.gov-integration-*.jar /opt/keycloak/providers/
COPY --from=builder /usr/src/keycloak-project/extensions/keycloak-api-key-demo/api-key-module/target/deploy/api-key-module-*.jar /opt/keycloak/providers/
COPY --from=builder /usr/src/keycloak-project/extensions/keycloak-api-key-demo/dashboard-service/target/dashboard-service-*.jar /opt/keycloak/providers/

# Set ownership of providers directory
RUN chown -R keycloak:keycloak /opt/keycloak/providers/

# Standard Keycloak environment variables
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_HOSTNAME=localhost

WORKDIR /opt/keycloak

# Switch to keycloak user
USER keycloak

# Run Keycloak's build command to optimize and incorporate custom providers with extra features
RUN /opt/keycloak/bin/kc.sh build --features=preview,admin-fine-grained-authz,declarative-user-profile,dynamic-scopes,client-policies,ciba,par,dpop,step-up-authentication,recovery-codes,update-email,scripts,token-exchange,openshift-integration,multi-site

# Define the entrypoint and default command for running Keycloak
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
