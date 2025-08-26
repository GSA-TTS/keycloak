# WebAuthn Docker Setup for USAI Keycloak

This document describes the automated WebAuthn configuration that is built into the Docker container for the USAI Keycloak setup.

## Overview

The Docker container now automatically:
1. Builds Keycloak with WebAuthn preview features enabled
2. Installs the WebAuthn configuration scripts
3. Configures a `usai-webauthn` realm with passwordless authentication
4. Applies the USAI theme with the modified login form (no username/password fields)

## What Happens Automatically

When you start the container with `docker-compose up`, the following occurs:

### 1. Container Build
- WebAuthn configuration scripts are copied into the container
- `jq` JSON processor is installed for script functionality
- All scripts are made executable

### 2. Keycloak Startup
- Keycloak builds with WebAuthn preview features: `account2`, `account_api`
- Server starts in the background
- Entrypoint script waits for Keycloak to be ready

### 3. Automatic WebAuthn Configuration
- Creates `usai-webauthn` realm
- Configures WebAuthn authentication flow with:
  - Passwordless authentication (primary)
  - Password + second factor (fallback)
  - Cookie-based SSO
- Sets up WebAuthn policies for `usai.gov` domain
- Creates test user: `testuser` (password: `testuser`)
- Applies USAI theme to the realm

## Quick Start

```bash
# Start the services
docker-compose up -d

# Wait for startup to complete (about 2-3 minutes)
docker-compose logs -f keycloak

# Access the realm
open http://localhost:8080/realms/usai-webauthn/account
```

## Accessing the WebAuthn Realm

### Admin Console
- URL: http://localhost:8080/admin/
- Username: `admin`
- Password: `admin`
- Navigate to: `usai-webauthn` realm

### User Login
- URL: http://localhost:8080/realms/usai-webauthn/protocol/openid-connect/auth?client_id=usai-client&response_type=code&redirect_uri=http://localhost:8080
- Test user: `testuser` / `testuser`
- Will be prompted to register WebAuthn security key on first login

### Account Management
- URL: http://localhost:8080/realms/usai-webauthn/account
- Users can manage their security keys here

## Configuration Details

### Environment Variables

The following environment variables control the WebAuthn setup:

```yaml
# In docker-compose.yml
environment:
  KEYCLOAK_ADMIN: admin                    # Admin username
  KEYCLOAK_ADMIN_PASSWORD: admin           # Admin password
  KC_FEATURES: "...,account2,account_api"  # Includes WebAuthn features
  SKIP_WEBAUTHN_CONFIG: ""                 # Set to skip auto-config
```

### WebAuthn Realm Configuration

The `usai-webauthn` realm includes:

- **Authentication Flow**: `Browser-WebAuthn-USAI`
  - Cookie (SSO)
  - Username form
  - WebAuthn passwordless OR password + 2FA
- **WebAuthn Policies**:
  - Relying Party: "USAI"
  - RP ID: "usai.gov"
  - User verification required for passwordless
  - Signature algorithms: ES256, RS256
- **Theme**: USAI custom theme (no username/password form)
- **Client**: `usai-client` configured for USAI domains

### Files Added to Container

```
/opt/keycloak/webauthn-config/
├── keycloak-configuration.sh          # Main configuration script
├── keycloak-configuration-helpers.sh  # Helper functions
├── realm_master.sh                    # Master realm config
├── realm_usai_webauthn.sh            # WebAuthn realm config
├── setup.sh                          # Interactive setup (not used in Docker)
└── README.md                         # Documentation
```

## Customization

### Skipping Auto-Configuration

To skip the automatic WebAuthn configuration:

```yaml
# In docker-compose.yml
environment:
  SKIP_WEBAUTHN_CONFIG: "true"
```

### Manual Configuration

If you skip auto-configuration, you can run it manually:

```bash
# Enter the container
docker-compose exec keycloak bash

# Run the configuration
cd /opt/keycloak/webauthn-config
export KCADM="/opt/keycloak/bin/kcadm.sh"
export HOST_FOR_KCADM="localhost"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="admin"
./keycloak-configuration.sh
```

### Modifying the Configuration

To customize the WebAuthn setup:

1. Edit the scripts in `webauthn-config/`
2. Rebuild the container: `docker-compose build`
3. Restart: `docker-compose up -d`

## Troubleshooting

### Check Container Logs

```bash
# View all logs
docker-compose logs keycloak

# Follow logs in real-time
docker-compose logs -f keycloak

# Check for WebAuthn configuration messages
docker-compose logs keycloak | grep -i webauthn
```

### Common Issues

1. **Configuration fails**: Check that Keycloak is fully started before configuration runs
2. **WebAuthn not working**: Ensure browser supports WebAuthn (Chrome recommended)
3. **Theme not applied**: Verify USAI theme files are properly copied during build

### Manual Verification

```bash
# Check if realm exists
curl -s http://localhost:8080/realms/usai-webauthn/.well-known/openid_configuration

# Check WebAuthn configuration
docker-compose exec keycloak /opt/keycloak/bin/kcadm.sh get realms/usai-webauthn --fields webAuthnPolicyRpId
```

## Security Considerations

### Production Deployment

For production use:

1. **Change default passwords**:
   ```yaml
   environment:
     KEYCLOAK_ADMIN: your-admin-user
     KEYCLOAK_ADMIN_PASSWORD: your-secure-password
   ```

2. **Use HTTPS**:
   - WebAuthn requires HTTPS in production
   - Configure proper SSL certificates

3. **Update redirect URIs**:
   - Modify `realm_usai_webauthn.sh` to use production URLs
   - Remove localhost redirects

4. **Database security**:
   - Use external PostgreSQL with proper credentials
   - Enable SSL for database connections

### WebAuthn Security

- User verification is required for passwordless authentication
- Security keys are bound to the `usai.gov` domain
- Backup authentication methods (password + OTP) are available
- Users should register multiple security keys for redundancy

## Integration with Existing Setup

This WebAuthn configuration works seamlessly with:

- ✅ **USAI Theme**: Custom login theme with removed username/password form
- ✅ **Login.gov Integration**: Can coexist with other identity providers
- ✅ **API Key Demo**: Other extensions continue to work
- ✅ **Custom Messages**: Identity provider labels are customized

## Browser Compatibility

WebAuthn works best with:
- **Chrome/Chromium** (recommended)
- **Firefox** (good support)
- **Safari** (limited support)
- **Edge** (good support)

## References

- [Keycloak WebAuthn Documentation](https://www.keycloak.org/docs/latest/server_admin/#webauthn)
- [WebAuthn Specification](https://www.w3.org/TR/webauthn-2/)
- [FIDO Alliance](https://fidoalliance.org/)
- [WebAuthn Browser Support](https://caniuse.com/webauthn)
