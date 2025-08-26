#!/usr/bin/env bash

# Master realm configuration for WebAuthn setup
# Based on Keycloak WebAuthn Tutorial

echo ""
echo "================================="
echo "Configuring master realm..."
echo "================================="
echo ""

# Ensure master realm uses the default browser flow with username/password login
echo "Ensuring master realm has proper login form..."

# Reset browser flow to default to ensure login form is available
echo "Setting browser flow to default browser flow..."
$KCADM update realms/master -s browserFlow=browser

# Ensure the default browser flow exists and has username/password form
echo "Verifying browser flow configuration..."
BROWSER_FLOW_EXISTS=$($KCADM get authentication/flows -r master --fields alias | jq -r '.[] | select(.alias=="browser") | .alias' 2>/dev/null || echo "")

if [[ -z "$BROWSER_FLOW_EXISTS" ]]; then
    echo "Warning: Default browser flow not found. This should not happen in a standard Keycloak installation."
else
    echo "✓ Default browser flow is available"
fi

# Ensure username/password authentication is enabled
echo "Ensuring username/password authentication is available..."

# Remove any problematic identity providers from master realm
echo "Checking for external identity providers in master realm..."
MASTER_PROVIDERS=$($KCADM get identity-provider/instances -r master 2>/dev/null || echo "[]")
if echo "$MASTER_PROVIDERS" | jq -e '. | length > 0' > /dev/null 2>&1; then
    echo "Found external identity providers in master realm. Removing them to ensure admin access..."
    echo "$MASTER_PROVIDERS" | jq -r '.[].alias' | while read -r alias; do
        if [[ -n "$alias" ]]; then
            echo "Removing identity provider: $alias"
            $KCADM delete identity-provider/instances/$alias -r master 2>/dev/null || echo "Failed to remove $alias (may not exist)"
        fi
    done
else
    echo "✓ No external identity providers found in master realm"
fi

# Ensure login theme is set to default (not USAI theme)
echo "Setting master realm login theme to default..."
$KCADM update realms/master -s loginTheme=""

# Ensure registration is disabled for master realm (security)
echo "Disabling user registration for master realm..."
$KCADM update realms/master -s registrationAllowed=false

# Ensure email verification is not required for master realm
echo "Disabling email verification requirement for master realm..."
$KCADM update realms/master -s verifyEmail=false

echo ""
echo "Master realm configuration completed."
echo "✓ Login form available at: http://localhost:8080"
echo "✓ Admin credentials: admin/admin"
echo "✓ No external identity providers"
echo "✓ Default Keycloak theme"
