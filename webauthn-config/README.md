# WebAuthn Configuration for Keycloak Realms

This directory contains scripts and configuration files to enable WebAuthn authentication for any Keycloak realm.

## Files

- `configure-webauthn-realm.sh` - Main configuration script
- `README.md` - This file

## Quick Start

1. **Make script executable** (if not already):
   ```bash
   chmod +x configure-webauthn-realm.sh
   ```

2. **Configure WebAuthn for a realm**:
   ```bash
   ./configure-webauthn-realm.sh YOUR_REALM_NAME
   ```

3. **Set USAI theme** (if needed):
   ```bash
   $KEYCLOAK_HOME/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password admin
   $KEYCLOAK_HOME/bin/kcadm.sh update realms/YOUR_REALM_NAME -s loginTheme="usai"
   ```

## Environment Variables

Set these environment variables to customize the configuration:

```bash
export KEYCLOAK_HOME="/opt/keycloak"          # Path to Keycloak installation
export HOST_FOR_KCADM="localhost:8080"       # Keycloak host:port
export KEYCLOAK_USER="admin"                 # Admin username
export KEYCLOAK_PASSWORD="admin"             # Admin password
```

## What the Script Does

1. **Creates Authentication Flow**: `Browser-WebAuthn-USAI`
2. **Configures WebAuthn Policies**: Security settings for USAI
3. **Registers Required Actions**: WebAuthn registration prompts
4. **Sets Flow Binding**: Makes the new flow active for the realm

## Authentication Flow Structure

```
Browser-WebAuthn-USAI
├── Cookie (ALTERNATIVE) - SSO support
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

## Usage Examples

### Single Realm
```bash
./configure-webauthn-realm.sh myrealm
```

### Multiple Realms
```bash
for realm in realm1 realm2 realm3; do
    ./configure-webauthn-realm.sh "$realm"
done
```

### Docker Environment
```bash
export KEYCLOAK_HOME="/opt/keycloak"
export HOST_FOR_KCADM="keycloak:8080"
./configure-webauthn-realm.sh myrealm
```

## Troubleshooting

### Prerequisites Check
```bash
# Check if jq is installed
which jq

# Check if Keycloak is running
curl http://localhost:8080/health

# List available realms
$KEYCLOAK_HOME/bin/kcadm.sh get realms --fields realm
```

### Common Issues

1. **jq not found**: Install with `apt-get install jq` or `brew install jq`
2. **Connection refused**: Ensure Keycloak is running and accessible
3. **Authentication failed**: Verify admin credentials
4. **Realm not found**: Check realm name spelling and existence

### Debug Mode
```bash
set -x
./configure-webauthn-realm.sh YOUR_REALM_NAME
```

## Security Notes

- WebAuthn requires HTTPS in production
- Update `webAuthnPolicyRpId` from "usai.gov" to your actual domain
- Ensure users have backup authentication methods
- Consider user training for security key usage

## Integration with USAI Theme

The script configures WebAuthn to work seamlessly with the USAI theme templates:

- `webauthn-authenticate.ftl` - Security key authentication
- `webauthn-register.ftl` - Security key registration
- `webauthn-error.ftl` - Error handling
- `login.ftl` - Main login with WebAuthn support
- `passkeys.ftl` - Conditional UI for passkeys

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Keycloak logs for detailed error messages
3. Verify browser compatibility for WebAuthn
4. Ensure security keys are FIDO2/WebAuthn compatible
