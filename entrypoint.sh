#!/bin/bash
set -e

echo "Starting Keycloak entrypoint script..."

# Build Keycloak with the features specified in KC_FEATURES environment variable
# Default to enabling WebAuthn preview features
if [ -n "$KC_FEATURES" ]; then
    echo "Building Keycloak with features: $KC_FEATURES"
    /opt/keycloak/bin/kc.sh build --features="$KC_FEATURES"
else
    echo "Building Keycloak with WebAuthn preview features..."
    /opt/keycloak/bin/kc.sh build --features="account-api,web-authn,passkeys"
fi

# If no arguments are provided, default to "start --optimized"
if [ $# -eq 0 ]; then
    set -- start --optimized
fi

# Function to wait for Keycloak to be ready
wait_for_keycloak() {
    echo "Waiting for Keycloak to be ready..."
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
            echo "Keycloak is ready!"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts: Keycloak not ready yet, waiting..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    echo "Keycloak failed to become ready after $max_attempts attempts"
    return 1
}

# Function to configure WebAuthn
configure_webauthn() {
    echo "Configuring WebAuthn for realms..."
    
    # Set environment variables for the configuration script
    export KEYCLOAK_HOME="/opt/keycloak"
    export KCADM="/opt/keycloak/bin/kcadm.sh"
    export HOST_FOR_KCADM="localhost:8080"
    export KEYCLOAK_USER="${KEYCLOAK_ADMIN:-admin}"
    export KEYCLOAK_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
    
    # Change to the webauthn-config directory
    cd /opt/keycloak/webauthn-config
    
    # Configure WebAuthn for specified realms or default realm
    if [ -n "$WEBAUTHN_REALMS" ]; then
        # Configure for specified realms (comma-separated)
        IFS=',' read -ra REALM_ARRAY <<< "$WEBAUTHN_REALMS"
        for realm in "${REALM_ARRAY[@]}"; do
            realm=$(echo "$realm" | xargs)  # trim whitespace
            echo "Configuring WebAuthn for realm: $realm"
            if ./configure-webauthn-realm.sh "$realm"; then
                echo "WebAuthn configuration completed for realm: $realm"
            else
                echo "WebAuthn configuration failed for realm: $realm, continuing..."
            fi
        done
    else
        echo "No WEBAUTHN_REALMS specified, skipping automatic WebAuthn configuration"
        echo "To configure WebAuthn for a realm, set WEBAUTHN_REALMS environment variable"
        echo "Example: WEBAUTHN_REALMS=myrealm,anotherrealm"
    fi
    
    # Return to the original directory
    cd /opt/keycloak
}

# Start Keycloak in the background if we're doing a normal start
if [[ "$1" == "start" || "$1" == "start-dev" ]]; then
    echo "Starting Keycloak server with command: $@"
    /opt/keycloak/bin/kc.sh "$@" &
    KEYCLOAK_PID=$!
    
    # Wait for Keycloak to be ready, then configure WebAuthn
    if wait_for_keycloak; then
        # Only configure WebAuthn if SKIP_WEBAUTHN_CONFIG is not set
        if [ -z "$SKIP_WEBAUTHN_CONFIG" ]; then
            configure_webauthn
        else
            echo "Skipping WebAuthn configuration (SKIP_WEBAUTHN_CONFIG is set)"
        fi
    fi
    
    # Wait for the Keycloak process to finish
    wait $KEYCLOAK_PID
else
    # For other commands, execute directly
    echo "Executing command: $@"
    if [[ "$1" == "show-config" ]]; then
        exec /opt/keycloak/bin/kc.sh "$@"
    else
        exec "$@"
    fi
fi
