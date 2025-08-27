#!/bin/bash

# Script to diagnose and fix login.gov identity provider configuration issues

set -e

echo "==================================="
echo "Login.gov Identity Provider Fix"
echo "==================================="

# Check if Keycloak is running
if ! curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
    echo "Error: Keycloak is not running or not ready"
    echo "Please start Keycloak first"
    exit 1
fi

# Set up kcadm
KCADM="/opt/keycloak/bin/kcadm.sh"
HOST_FOR_KCADM="localhost"
KEYCLOAK_USER="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"

echo "Authenticating with Keycloak..."
$KCADM config credentials --server http://$HOST_FOR_KCADM:8080 --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD

echo ""
echo "Checking for existing login.gov identity providers..."

# Check master realm
echo "Checking master realm..."
MASTER_PROVIDERS=$($KCADM get identity-provider/instances -r master 2>/dev/null || echo "[]")
if echo "$MASTER_PROVIDERS" | grep -q "login.gov\|login-gov"; then
    echo "WARNING: Found login.gov identity provider in master realm"
    echo "$MASTER_PROVIDERS" | jq '.[] | select(.alias | contains("login")) | {alias: .alias, providerId: .providerId, enabled: .enabled}'
    
    echo ""
    echo "IMPORTANT: The master realm should use default Keycloak login for admin access."
    echo "Removing login.gov from master realm is recommended to prevent login issues."
    echo ""
    echo "Do you want to remove the login.gov identity provider from master realm? (Y/n)"
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo "Keeping login.gov identity provider in master realm (not recommended)"
    else
        # Get the alias of the login.gov provider
        LOGIN_GOV_ALIAS=$(echo "$MASTER_PROVIDERS" | jq -r '.[] | select(.alias | contains("login")) | .alias' | head -1)
        if [ -n "$LOGIN_GOV_ALIAS" ]; then
            echo "Removing identity provider: $LOGIN_GOV_ALIAS"
            $KCADM delete identity-provider/instances/$LOGIN_GOV_ALIAS -r master
            echo "Identity provider removed successfully from master realm"
        fi
    fi
else
    echo "✓ No login.gov identity provider found in master realm (this is correct)"
fi

# Check usai-webauthn realm if it exists
echo ""
echo "Checking usai-webauthn realm..."
if $KCADM get realms/usai-webauthn > /dev/null 2>&1; then
    USAI_PROVIDERS=$($KCADM get identity-provider/instances -r usai-webauthn 2>/dev/null || echo "[]")
    if echo "$USAI_PROVIDERS" | grep -q "login.gov\|login-gov"; then
        echo "Found login.gov identity provider in usai-webauthn realm"
        echo "$USAI_PROVIDERS" | jq '.[] | select(.alias | contains("login")) | {alias: .alias, providerId: .providerId, enabled: .enabled}'
        
        echo ""
        echo "Do you want to remove the login.gov identity provider from usai-webauthn realm? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Get the alias of the login.gov provider
            LOGIN_GOV_ALIAS=$(echo "$USAI_PROVIDERS" | jq -r '.[] | select(.alias | contains("login")) | .alias' | head -1)
            if [ -n "$LOGIN_GOV_ALIAS" ]; then
                echo "Removing identity provider: $LOGIN_GOV_ALIAS"
                $KCADM delete identity-provider/instances/$LOGIN_GOV_ALIAS -r usai-webauthn
                echo "Identity provider removed successfully"
            fi
        fi
    else
        echo "No login.gov identity provider found in usai-webauthn realm"
    fi
else
    echo "usai-webauthn realm does not exist yet"
fi

echo ""
echo "==================================="
echo "Diagnosis complete!"
echo "==================================="
echo ""
echo "If you removed any identity providers, you should restart Keycloak to ensure"
echo "the changes take effect and the error is resolved."
echo ""
echo "To restart Keycloak:"
echo "  docker-compose down"
echo "  docker-compose up --build"
