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

# If no arguments are provided, default to "start --optimized"
if [ $# -eq 0 ]; then
    set -- start --optimized
fi

# Execute the command - prepend with kc.sh if the first argument is a Keycloak command
echo "Starting Keycloak server with command: $@"
if [[ "$1" == "start" || "$1" == "start-dev" || "$1" == "show-config" ]]; then
    exec /opt/keycloak/bin/kc.sh "$@"
else
    exec "$@"
fi