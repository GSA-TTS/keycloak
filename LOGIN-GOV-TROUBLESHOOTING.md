# Login.gov Identity Provider Troubleshooting Guide

## Issue Description

You may encounter the following error when starting Keycloak:

```
keycloak-1  | 2025-08-26 15:42:05,557 ERROR [org.keycloak.services.resources.IdentityBrokerService] (executor-thread-4) couldNotSendAuthenticationRequestMessage: org.keycloak.broker.provider.IdentityBrokerException: Could not create authentication request.
keycloak-1  | Caused by: java.lang.IllegalArgumentException: Param was null
keycloak-1  |   at org.jboss.resteasy.reactive.common.jaxrs.UriBuilderImpl.uriTemplate(UriBuilderImpl.java:164)
```

## Root Cause

This error occurs when there's a login.gov identity provider configuration in the Keycloak database that has missing or null parameters required for creating the authorization URL. This typically happens when:

1. A login.gov identity provider was previously configured but not properly set up
2. The identity provider configuration is incomplete or corrupted
3. Required configuration parameters (like authorization URL, token URL, etc.) are missing

**Important Note**: The master realm should remain unchanged and continue using the default Keycloak login. The USAI WebAuthn configuration and login.gov integration should only apply to the `usai-webauthn` realm, ensuring administrators can always access the master realm normally.

## Solutions

### Solution 1: Master Realm Protection (Recommended)

The master realm configuration has been updated to ensure it always has a proper login form and removes any external identity providers that could cause issues.

**First time setup or after code changes:**
```bash
docker-compose down
docker-compose up --build
```

**Subsequent runs (no code changes):**
```bash
docker-compose down
docker-compose up
```

**Note**: The `--build` flag is only needed when:
- Running for the first time
- Dockerfile or source code has changed
- You want to rebuild the image with latest changes

### Solution 2: Clean Up Problematic Identity Providers

If Keycloak starts successfully, you can use the provided diagnostic script to identify and remove problematic login.gov identity providers:

1. Start Keycloak:
   ```bash
   docker-compose up --build
   ```

2. Wait for Keycloak to be ready, then run the diagnostic script:
   ```bash
   ./fix-login-gov-issue.sh
   ```

3. Follow the prompts to remove any problematic identity providers.

4. Restart Keycloak:
   ```bash
   docker-compose down
   docker-compose up --build
   ```

### Solution 3: Manual Cleanup via Admin Console

If you can access the Keycloak admin console:

1. Go to http://localhost:8080
2. Login with admin/admin
3. Navigate to the master realm
4. Go to Identity Providers
5. Look for any login.gov or login-gov providers
6. Delete any incomplete or problematic providers
7. Restart Keycloak

### Solution 4: Database Cleanup (Advanced)

If the above solutions don't work, you may need to clean up the database:

```bash
# Stop Keycloak
docker-compose down

# Remove the database volume (WARNING: This will delete all Keycloak data)
docker volume rm keycloak_postgres_data

# Start fresh
docker-compose up --build
```

## Realm Configuration

### Master Realm
- **Purpose**: Administrative access to Keycloak
- **Login Method**: Default Keycloak username/password (admin/admin)
- **Identity Providers**: Should NOT have login.gov or other external providers
- **Access URL**: http://localhost:8080 (redirects to master realm)

### USAI-WebAuthn Realm
- **Purpose**: End-user authentication with WebAuthn and login.gov
- **Login Method**: WebAuthn passwordless + login.gov integration
- **Identity Providers**: Can have login.gov and other external providers
- **Access URL**: http://localhost:8080/realms/usai-webauthn

## Enabling WebAuthn Configuration

Now that the master realm access issue has been resolved, you can safely enable the WebAuthn configuration:

### Step 1: Remove the Skip Flag

Edit `docker-compose.yml` and remove the `SKIP_WEBAUTHN_CONFIG: "true"` line:

```yaml
  keycloak:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
      KC_HOSTNAME: localhost
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_FEATURES: "token-exchange,admin-fine-grained-authz,admin-api,admin,authorization,ciba,client-policies,device-flow,impersonation,kerberos,login,organization,par,persistent-user-sessions,token-exchange-standard,user-event-metrics,client-secret-rotation,account-api,web-authn,passkeys"
      # SKIP_WEBAUTHN_CONFIG: "true"  <- Remove or comment out this line
```

### Step 2: Restart Keycloak with WebAuthn Enabled

```bash
docker-compose down
docker-compose up --build
```

### Step 3: Verify Access

After startup, you should be able to access:

1. **Master Realm Admin Console**: http://localhost:8080/admin
   - Login: admin/admin
   - Purpose: Keycloak administration
   - Should use standard username/password login

2. **USAI WebAuthn Realm**: http://localhost:8080/realms/usai-webauthn
   - Purpose: End-user authentication with WebAuthn
   - Features: Passwordless login, login.gov integration
   - Test user: testuser/testuser (will require WebAuthn setup on first login)

### Step 4: Test WebAuthn Functionality

1. Navigate to the USAI realm: http://localhost:8080/realms/usai-webauthn
2. Try logging in with the test user: `testuser` / `testuser`
3. You should be prompted to set up a WebAuthn security key
4. Follow the browser prompts to register your authenticator

### Troubleshooting WebAuthn Setup

If you encounter issues with WebAuthn:

1. **Browser Compatibility**: Ensure you're using a modern browser that supports WebAuthn (Chrome, Firefox, Safari, Edge)
2. **HTTPS Requirement**: For production, WebAuthn requires HTTPS. For localhost development, HTTP is acceptable
3. **Security Key**: You can use:
   - Hardware security keys (YubiKey, etc.)
   - Platform authenticators (TouchID, Windows Hello, etc.)
   - Browser-based authenticators for testing

**Note**: The WebAuthn configuration only affects the `usai-webauthn` realm and will not modify the master realm's login behavior. The master realm will always remain accessible with username/password authentication.

## Prevention

To prevent this issue in the future:

1. Always ensure login.gov identity providers are fully configured with all required parameters
2. Test identity provider configurations before deploying
3. Use the provided diagnostic script to check for issues before major deployments
4. Consider using environment-specific configuration files to manage identity providers

## Files Modified

- `webauthn-config/realm_master.sh`: Enhanced to ensure master realm has proper login form and removes external identity providers
- `entrypoint.sh`: Restored WebAuthn configuration with proper master realm protection
- `docker-compose.yml`: Removed temporary `SKIP_WEBAUTHN_CONFIG` workaround
- `fix-login-gov-issue.sh`: New diagnostic and cleanup script with master realm protection warnings

## Related Files

- `keycloak-login.gov-integration/`: The login.gov integration extension
- `webauthn-config/`: WebAuthn configuration scripts that may trigger the issue
- `themes/src/main/resources/theme/usai/`: USAI theme with login.gov styling
