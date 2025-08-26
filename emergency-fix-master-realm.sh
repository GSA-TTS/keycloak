#!/bin/bash

# Emergency script to fix master realm access

set -e

echo "==================================="
echo "EMERGENCY: Fixing Master Realm Access"
echo "==================================="

# Check if Keycloak is running
if ! curl -s http://localhost:8080/health/ready > /dev/null 2>&1; then
    echo "Error: Keycloak is not running or not ready"
    echo "Please start Keycloak first with: docker-compose up"
    exit 1
fi

# Set up kcadm
KCADM="/opt/keycloak/bin/kcadm.sh"
HOST_FOR_KCADM="localhost"
KEYCLOAK_USER="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"

echo "Attempting to authenticate with Keycloak master realm..."

# Try to authenticate directly with master realm
if ! $KCADM config credentials --server http://$HOST_FOR_KCADM:8080 --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD; then
    echo "ERROR: Cannot authenticate with master realm!"
    echo "This suggests the master realm has been compromised or overridden."
    echo ""
    echo "IMMEDIATE ACTIONS:"
    echo "1. Stop Keycloak: docker-compose down"
    echo "2. Reset database: docker volume rm keycloak_postgres_data"
    echo "3. Restart with WebAuthn disabled: SKIP_WEBAUTHN_CONFIG=true docker-compose up --build"
    exit 1
fi

echo "✓ Successfully authenticated with master realm"

echo ""
echo "Checking master realm configuration..."

# Check if master realm exists and is accessible
MASTER_REALM=$($KCADM get realms/master 2>/dev/null || echo "")
if [[ -z "$MASTER_REALM" ]]; then
    echo "ERROR: Master realm not found or not accessible!"
    exit 1
fi

echo "✓ Master realm exists and is accessible"

# Reset master realm to defaults
echo ""
echo "Resetting master realm to safe defaults..."

# Ensure master realm uses default browser flow
echo "Setting browser flow to default..."
$KCADM update realms/master -s browserFlow=browser

# Remove any custom themes from master realm
echo "Removing custom themes from master realm..."
$KCADM update realms/master -s loginTheme=""
$KCADM update realms/master -s accountTheme=""
$KCADM update realms/master -s adminTheme=""
$KCADM update realms/master -s emailTheme=""

# Remove any identity providers from master realm
echo "Removing identity providers from master realm..."
MASTER_PROVIDERS=$($KCADM get identity-provider/instances -r master 2>/dev/null || echo "[]")
if echo "$MASTER_PROVIDERS" | jq -e '. | length > 0' > /dev/null 2>&1; then
    echo "Found identity providers in master realm. Removing them..."
    echo "$MASTER_PROVIDERS" | jq -r '.[].alias' | while read -r alias; do
        if [[ -n "$alias" ]]; then
            echo "Removing identity provider: $alias"
            $KCADM delete identity-provider/instances/$alias -r master 2>/dev/null || echo "Failed to remove $alias"
        fi
    done
else
    echo "✓ No identity providers found in master realm"
fi

# Ensure registration is disabled for master realm
echo "Disabling user registration for master realm..."
$KCADM update realms/master -s registrationAllowed=false

# Ensure email verification is not required
echo "Disabling email verification for master realm..."
$KCADM update realms/master -s verifyEmail=false

# Check if there are any problematic clients in master realm
echo ""
echo "Checking master realm clients..."
MASTER_CLIENTS=$($KCADM get clients -r master --fields clientId,redirectUris 2>/dev/null || echo "[]")
PROBLEMATIC_CLIENTS=$(echo "$MASTER_CLIENTS" | jq -r '.[] | select(.redirectUris[]? | contains("localhost")) | .clientId' 2>/dev/null || echo "")

if [[ -n "$PROBLEMATIC_CLIENTS" ]]; then
    echo "WARNING: Found clients with localhost redirects in master realm:"
    echo "$PROBLEMATIC_CLIENTS"
    echo "These might be causing redirect issues."
fi

echo ""
echo "==================================="
echo "Master Realm Fix Complete!"
echo "==================================="
echo ""
echo "✓ Master realm browser flow reset to default"
echo "✓ Custom themes removed from master realm"
echo "✓ Identity providers removed from master realm"
echo "✓ Registration disabled"
echo "✓ Email verification disabled"
echo ""
echo "You should now be able to access:"
echo "- Admin Console: http://localhost:8080/admin"
echo "- Master Realm: http://localhost:8080/realms/master/account"
echo ""
echo "Login with: admin/admin"
echo ""
echo "If you still can't access the master realm, run:"
echo "  docker-compose down"
echo "  docker volume rm keycloak_postgres_data"
echo "  SKIP_WEBAUTHN_CONFIG=true docker-compose up --build"
