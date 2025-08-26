#!/usr/bin/env bash

# Main configuration script for WebAuthn setup
# Based on Keycloak WebAuthn Tutorial

set -e

# Source helper functions
source "$(dirname "$0")/keycloak-configuration-helpers.sh"

# Check required environment variables
check_environment() {
    if [[ -z "$KCADM" ]]; then
        echo "Error: KCADM environment variable not set"
        echo "Example: export KCADM=/path/to/keycloak/bin/kcadm.sh"
        exit 1
    fi
    
    if [[ -z "$HOST_FOR_KCADM" ]]; then
        echo "Error: HOST_FOR_KCADM environment variable not set"
        echo "Example: export HOST_FOR_KCADM=localhost"
        exit 1
    fi
    
    if [[ -z "$KEYCLOAK_USER" ]]; then
        echo "Error: KEYCLOAK_USER environment variable not set"
        echo "Example: export KEYCLOAK_USER=admin"
        exit 1
    fi
    
    if [[ -z "$KEYCLOAK_PASSWORD" ]]; then
        echo "Error: KEYCLOAK_PASSWORD environment variable not set"
        echo "Example: export KEYCLOAK_PASSWORD=admin"
        exit 1
    fi
}

main() {
    echo "================================="
    echo "Keycloak WebAuthn Configuration"
    echo "================================="
    
    check_environment
    
    # Authenticate with Keycloak
    echo "Authenticating with Keycloak..."
    $KCADM config credentials --server http://$HOST_FOR_KCADM:8080 --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
    
    # Configure master realm
    echo "Configuring master realm..."
    source "$(dirname "$0")/realm_master.sh"
    
    # Configure WebAuthn realm
    echo "Configuring WebAuthn realm..."
    source "$(dirname "$0")/realm_usai_webauthn.sh"
    
    echo ""
    echo "================================="
    echo "Configuration completed successfully!"
    echo "================================="
    echo ""
    echo "Next steps:"
    echo "1. Restart Keycloak with WebAuthn preview features enabled:"
    echo "   ./bin/standalone.sh -Dkeycloak.profile.feature.account2=enabled -Dkeycloak.profile.feature.account_api=enabled"
    echo ""
    echo "2. Access the realm at: http://$HOST_FOR_KCADM:8080/realms/usai-webauthn"
    echo ""
}

main "$@"
