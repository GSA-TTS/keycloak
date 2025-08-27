# WebAuthn Setup Guide for All Keycloak Realms

This guide explains how to configure WebAuthn authentication for any Keycloak realm, making it available to all realms (old and new), not just the master realm.

## Overview

WebAuthn (Web Authentication) is a W3C standard that enables strong, passwordless authentication using security keys, biometrics, or other authenticators. This setup provides:

- **Passwordless Authentication**: Users can log in using only their security key/passkey
- **Multi-Factor Authentication**: WebAuthn as a second factor after password
- **Universal Support**: Works with any Keycloak realm
- **USAI Theme Integration**: Styled components following government design standards

## Prerequisites

1. **Keycloak Installation**: Running Keycloak instance
2. **Admin Access**: Admin credentials for Keycloak
3. **jq**: JSON processor (install with `apt-get install jq` or `brew install jq`)
4. **HTTPS**: WebAuthn requires secure context (HTTPS)
5. **Compatible Browser**: Chrome, Firefox, Safari, or Edge with WebAuthn support

## Quick Setup

### Step 1: Configure WebAuthn for a Realm

Use the provided script to configure WebAuthn for any realm:

```bash
# Set environment variables (optional, defaults shown)
export KEYCLOAK_HOME="/opt/keycloak"
export HOST_FOR_KCADM="localhost:8080"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="admin"

# Configure WebAuthn for your realm
./webauthn-config/configure-webauthn-realm.sh YOUR_REALM_NAME
```

### Step 2: Apply USAI Theme

Set the USAI theme for your realm (if not already applied):

```bash
# Using kcadm.sh
$KEYCLOAK_HOME/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
$KEYCLOAK_HOME/bin/kcadm.sh update realms/YOUR_REALM_NAME -s loginTheme="usai"
```

### Step 3: Test the Configuration

1. Navigate to your realm's login page
2. Try logging in with an existing user
3. User will be prompted to register a security key
4. Follow the registration process
5. Future logins can use the security key

## What the Script Does

The `configure-webauthn-realm.sh` script performs the following configuration:

### 1. Authentication Flow Setup

Creates a new authentication flow called `Browser-WebAuthn-USAI` with:

```
Browser-WebAuthn-USAI
├── Cookie (ALTERNATIVE) - for SSO
└── Forms (ALTERNATIVE)
    ├── Username Form (REQUIRED)
    └── Passwordless_Or_Two-factors (REQUIRED)
        ├── WebAuthn Passwordless (ALTERNATIVE)
        └── Password_And_Second-factor (ALTERNATIVE)
            ├── Password Form (REQUIRED)
            └── Second-factor (CONDITIONAL)
                ├── Condition User Configured (REQUIRED)
                ├── WebAuthn Authenticator (ALTERNATIVE)
                └── OTP Form (ALTERNATIVE)
```

### 2. Required Actions

Registers and configures:
- `webauthn-register`: For second-factor security keys
- `webauthn-register-passwordless`: For passwordless security keys (set as default)

### 3. WebAuthn Policies

Configures security policies:
- User verification required for passwordless authentication
- Relying Party Entity Name: "USAI"
- Relying Party ID: "usai.gov"
- Signature algorithms: ES256, RS256

### 4. Flow Binding

Sets the new flow as the browser flow for the realm.

## Authentication Flows

### Flow 1: First-Time User
1. User logs in with username/password (or identity provider)
2. Keycloak presents WebAuthn registration as required action
3. User registers security key following USAI-styled wizard
4. Future logins can use passwordless authentication

### Flow 2: Passwordless Authentication
1. User enters username
2. WebAuthn challenge presented
3. User authenticates with security key
4. Access granted immediately

### Flow 3: Password + WebAuthn 2FA
1. User enters username and password
2. WebAuthn second-factor challenge
3. User authenticates with security key
4. Access granted

### Flow 4: Conditional UI (Passkeys)
1. User clicks in username field
2. Browser shows passkey suggestions (if available)
3. User selects passkey
4. Automatic authentication

## Supported Authenticators

### Platform Authenticators
- **Windows**: Windows Hello (fingerprint, face, PIN)
- **macOS**: Touch ID, Face ID
- **iOS**: Face ID, Touch ID
- **Android**: Fingerprint, face unlock

### External Authenticators
- **YubiKey**: All FIDO2/WebAuthn compatible models
- **Google Titan**: Security keys
- **SoloKeys**: Open-source security keys
- **Other FIDO2**: Any CTAP2 compatible authenticator

## Browser Compatibility

### Fully Supported
- **Chrome/Chromium 67+**: Full WebAuthn support
- **Firefox 60+**: Full WebAuthn support
- **Safari 14+**: WebAuthn support (limited platform authenticators)
- **Edge 18+**: Full WebAuthn support

## Configuration for Multiple Realms

### Batch Configuration

To configure WebAuthn for multiple realms:

```bash
#!/bin/bash
REALMS=("realm1" "realm2" "realm3")

for realm in "${REALMS[@]}"; do
    echo "Configuring WebAuthn for realm: $realm"
    ./webauthn-config/configure-webauthn-realm.sh "$realm"
done
```

### Docker Environment

For Docker deployments, set environment variables:

```bash
export KEYCLOAK_HOME="/opt/keycloak"
export HOST_FOR_KCADM="keycloak:8080"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="your-admin-password"

./webauthn-config/configure-webauthn-realm.sh YOUR_REALM_NAME
```

## Troubleshooting

### Common Issues

1. **Script fails with "jq not found"**
   ```bash
   # Install jq
   sudo apt-get install jq  # Ubuntu/Debian
   brew install jq          # macOS
   ```

2. **Authentication fails**
   ```bash
   # Check Keycloak is running
   curl http://localhost:8080/health
   
   # Verify admin credentials
   $KEYCLOAK_HOME/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
   ```

3. **Realm not found**
   ```bash
   # List available realms
   $KEYCLOAK_HOME/bin/kcadm.sh get realms --fields realm
   ```

4. **WebAuthn not working in browser**
   - Ensure HTTPS is enabled (WebAuthn requires secure context)
   - Check browser compatibility
   - Verify security key is FIDO2/WebAuthn compatible

### Debug Mode

Run the script with debug output:

```bash
set -x
./webauthn-config/configure-webauthn-realm.sh YOUR_REALM_NAME
```

## Security Considerations

### Production Deployment

1. **Update Relying Party ID**: Change from "usai.gov" to your actual domain
2. **HTTPS Required**: WebAuthn only works over HTTPS
3. **User Training**: Provide user education about security keys
4. **Backup Authentication**: Ensure users have fallback methods

### Policy Configuration

Customize WebAuthn policies as needed:

```bash
# Require user verification for all WebAuthn
$KCADM update realms/YOUR_REALM -s webAuthnPolicyUserVerificationRequirement=required

# Set timeout for WebAuthn operations (milliseconds)
$KCADM update realms/YOUR_REALM -s webAuthnPolicyCreateTimeout=60000

# Configure allowed algorithms
$KCADM update realms/YOUR_REALM
