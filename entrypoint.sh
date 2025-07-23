# This is the Keycloak-recommended step for a container
# It uses runtime variables to create the server configuration.
/opt/keycloak/bin/kc.sh build

# This starts the server you just configured.
exec "$@"