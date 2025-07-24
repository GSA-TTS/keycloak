#!/bin/bash
set -e

echo "Starting Keycloak entrypoint script..."

# Build Keycloak with the features specified in KC_FEATURES environment variable
if [ -n "$KC_FEATURES" ]; then
    echo "Building Keycloak with features: $KC_FEATURES"
    /opt/keycloak/bin/kc.sh build --features="$KC_FEATURES"
else
    echo "Building Keycloak with default features..."
    /opt/keycloak/bin/kc.sh build
fi

# Execute the command passed to the container (CMD from Dockerfile)
echo "Starting Keycloak server..."
exec "$@"