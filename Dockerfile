FROM quay.io/keycloak/keycloak:23.0.6

# Copy the Login.gov extension JAR to the providers directory
COPY keycloak-login.gov-integration/target/login_gov-23.0.6.jar /opt/keycloak/providers/

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database
ENV KC_DB=postgres

# Set the hostname
ENV KC_HOSTNAME=localhost

# Add custom startup command to build the extension and start Keycloak
WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
