# Keycloak WebAuthn Configuration for USAI

This directory contains scripts to configure Keycloak with WebAuthn (passwordless authentication) support for the USAI theme.

## Overview

The configuration creates a new realm `usai-webauthn` with:
- WebAuthn passwordless authentication
- Traditional password + second factor authentication
- USAI custom theme integration
- Test user setup

## Prerequisites

1. **Keycloak Installation**: A running Keycloak instance
2. **Admin CLI Access**: The `kcadm.sh` script must be accessible
3. **jq**: JSON processor for parsing API responses
4. **Environment Variables**: Set the following variables:

```bash
export KCADM="/path/to/keycloak/bin/kcadm.sh"
export HOST_FOR_KCADM="localhost"  # or your Keycloak host
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="admin"
```

## Installation

### Step 1: Enable Preview Features

Start Keycloak with WebAuthn preview features enabled:

```bash
./bin/standalone.sh \
  -Dkeycloak.profile.feature.account2=enabled \
  -Dkeycloak.profile.feature.account_api=enabled
```

### Step 2: Run Configuration Script

Make the scripts executable and run the main configuration:

```bash
chmod +x webauthn-config/*.sh
cd webauthn-config
./keycloak-configuration.sh
```

## What Gets Configured

### Realm: `usai-webauthn`
- User registration enabled
- Event logging configured
- USAI login theme applied
- Account theme set to `keycloak-preview`

### Authentication Flow: `Browser-WebAuthn-USAI`
```
1. Cookie (SSO)
2. Forms (Subflow)
   ├── Username Form
   └── Passwordless Or Two-factors (Subflow)
       ├── WebAuthn Passwordless
       └── Password And Second-factor (Subflow)
           ├── Password Form
           └── Second-factor (Conditional Subflow)
               ├── Condition User Configured
               ├── WebAuthn Authenticator
               └── OTP Form
```

### Client: `usai-client`
- OpenID Connect protocol
- Public client
- Configured for USAI domains

### WebAuthn Policies
- Relying Party: "USAI"
- RP ID: "usai.gov"
- Signature algorithms: ES256, RS256
- User verification required for passwordless

### Test User
- Username: `testuser`
- Password: `testuser`
- Email: `test.user@usai.gov`
- Required to set up WebAuthn on first login

## Usage

### Accessing the Realm
- Admin Console: `http://localhost:8080/admin/master/console/#/usai-webauthn`
- Login URL: `http://localhost:8080/realms/usai-webauthn/protocol/openid-connect/auth?client_id=usai-client&response_type=code&redirect_uri=http://localhost:8080`

### Testing WebAuthn

1. **First Login**: 
   - Use username `testuser` and password `testuser`
   - You'll be prompted to register a WebAuthn security key
   - Use Chrome browser for best compatibility

2. **Subsequent Logins**:
   - Enter username `testuser`
   - Click "Try Another Way" to use passwordless authentication
   - Use your registered security key

### Managing Security Keys

Users can manage their WebAuthn security keys in the Account Console:
- URL: `http://localhost:8080/realms/usai-webauthn/account`
- Navigate to "Signing in" section
- Add/remove security keys as needed

## File Structure

```
webauthn-config/
├── keycloak-configuration.sh          # Main configuration script
├── keycloak-configuration-helpers.sh  # Helper functions
├── realm_master.sh                    # Master realm config (minimal)
├── realm_usai_webauthn.sh            # USAI WebAuthn realm config
└── README.md                         # This file
```

## Troubleshooting

### Common Issues

1. **jq not found**: Install jq JSON processor
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # CentOS/RHEL
   sudo yum install jq
   
   # macOS
   brew install jq
   ```

2. **Authentication failed**: Check environment variables
   ```bash
   echo $KCADM
   echo $HOST_FOR_KCADM
   echo $KEYCLOAK_USER
   ```

3. **WebAuthn not working**: Ensure preview features are enabled
   - Check Server Info in Admin Console
   - Verify `account2` and `account_api` features are enabled

4. **Theme not applied**: Verify USAI theme exists
   - Check `themes/src/main/resources/theme/usai/` directory
   - Restart Keycloak after theme changes

### Browser Compatibility

WebAuthn works best with:
- Chrome/Chromium (recommended)
- Firefox
- Safari (limited support)
- Edge

### Security Considerations

- In production, change default passwords
- Configure proper redirect URIs
- Use HTTPS for WebAuthn
- Consider backup authentication methods
- Regularly update Keycloak

## References

- [Keycloak WebAuthn Documentation](https://www.keycloak.org/docs/latest/server_admin/#webauthn)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn/)
- [FIDO Alliance](https://fidoalliance.org/)
