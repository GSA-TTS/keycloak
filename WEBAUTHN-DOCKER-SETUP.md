# WebAuthn Docker Setup Guide

This guide explains how to use WebAuthn authentication with the Keycloak Docker container.

## Docker Container Features

The Docker container includes:
- **WebAuthn Configuration Scripts**: Automatically configure WebAuthn for any realm
- **USAI Theme**: Pre-installed with WebAuthn support
- **Preview Features**: WebAuthn, passkeys, and account-api enabled by default
- **Automatic Configuration**: Optional automatic WebAuthn setup on container startup

## Environment Variables

### WebAuthn Configuration
- `WEBAUTHN_REALMS`: Comma-separated list of realms to configure WebAuthn for
- `SKIP_WEBAUTHN_CONFIG`: Set to any value to skip automatic WebAuthn configuration

### Keycloak Admin
- `KEYCLOAK_ADMIN`: Admin username (default: admin)
- `KEYCLOAK_ADMIN_PASSWORD`: Admin password (default: admin)

### Keycloak Features
- `KC_FEATURES`: Override default features (default: "account-api,web-authn,passkeys")

## Usage Examples

### Basic Usage with Automatic WebAuthn Configuration

```bash
docker run -d \
  --name keycloak-webauthn \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e WEBAUTHN_REALMS=myrealm,testrealm \
  your-keycloak-image:latest
```

### Docker Compose Example

```yaml
version: '3.8'
services:
  keycloak:
    image: your-keycloak-image:latest
    ports:
      - "8080:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      WEBAUTHN_REALMS: myrealm,production
      KC_HOSTNAME: localhost
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password
    depends_on:
      - postgres
    
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Manual Configuration (Skip Automatic Setup)

```bash
docker run -d \
  --name keycloak-manual \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e SKIP_WEBAUTHN_CONFIG=true \
  your-keycloak-image:latest
```

Then configure WebAuthn manually:

```bash
# Enter the container
docker exec -it keycloak-manual bash

# Configure WebAuthn for a specific realm
cd /opt/keycloak/webauthn-config
./configure-webauthn-realm.sh YOUR_REALM_NAME
```

## Container Startup Process

1. **Build Phase**: Keycloak builds with WebAuthn features enabled
2. **Start Phase**: Keycloak server starts in background
3. **Health Check**: Wait for Keycloak to be ready
4. **WebAuthn Configuration**: Automatically configure specified realms (if `WEBAUTHN_REALMS` is set)
5. **Ready**: Container is ready for use

## Logs and Monitoring

### View Container Logs
```bash
docker logs keycloak-webauthn
```

### Monitor WebAuthn Configuration
```bash
# Follow logs during startup
docker logs -f keycloak-webauthn

# Look for these log messages:
# "Configuring WebAuthn for realm: myrealm"
# "WebAuthn configuration completed for realm: myrealm"
```

### Health Check
```bash
# Check if Keycloak is ready
curl http://localhost:8080/health/ready

# Check if WebAuthn is configured
curl -s http://localhost:8080/realms/YOUR_REALM/.well-known/openid_configuration | jq .
```

## Troubleshooting

### Common Issues

1. **WebAuthn Configuration Fails**
   ```bash
   # Check if jq is installed in container
   docker exec keycloak-webauthn which jq
   
   # Check realm exists
   docker exec keycloak-webauthn /opt/keycloak/bin/kcadm.sh get realms --fields realm
   ```

2. **Container Won't Start**
   ```bash
   # Check logs for build errors
   docker logs keycloak-webauthn
   
   # Verify environment variables
   docker exec keycloak-webauthn env | grep KEYCLOAK
   ```

3. **WebAuthn Not Working**
   ```bash
   # Verify HTTPS (required for WebAuthn)
   # Check browser compatibility
   # Ensure security key is FIDO2 compatible
   ```

### Debug Mode

Run container with debug output:

```bash
docker run -d \
  --name keycloak-debug \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e WEBAUTHN_REALMS=myrealm \
  -e KC_LOG_LEVEL=DEBUG \
  your-keycloak-image:latest
```

### Manual WebAuthn Configuration

If automatic configuration fails, configure manually:

```bash
# Enter container
docker exec -it keycloak-webauthn bash

# Set environment variables
export KEYCLOAK_HOME="/opt/keycloak"
export HOST_FOR_KCADM="localhost:8080"
export KEYCLOAK_USER="admin"
export KEYCLOAK_PASSWORD="admin"

# Configure WebAuthn
cd /opt/keycloak/webauthn-config
./configure-webauthn-realm.sh YOUR_REALM_NAME
```

## Production Considerations

### Security
- Use strong admin passwords
- Enable HTTPS (required for WebAuthn)
- Update relying party ID from "usai.gov" to your domain
- Use secrets management for sensitive environment variables

### Performance
- Use external database (PostgreSQL recommended)
- Configure appropriate resource limits
- Enable health checks and monitoring

### Scaling
- Use external session storage for clustering
- Configure load balancer with sticky sessions
- Ensure consistent WebAuthn configuration across instances

## Example Production Docker Compose

```yaml
version: '3.8'
services:
  keycloak:
    image: your-keycloak-image:latest
    ports:
      - "8080:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD_FILE: /run/secrets/keycloak_admin_password
      WEBAUTHN_REALMS: production
      KC_HOSTNAME: auth.yourdomain.com
      KC_HOSTNAME_STRICT: true
      KC_PROXY: edge
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD_FILE: /run/secrets/db_password
      KC_HEALTH_ENABLED: true
      KC_METRICS_ENABLED: true
    secrets:
      - keycloak_admin_password
      - db_password
    depends_on:
      - postgres
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
    
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres_data:/var/lib/postgresql/data

secrets:
  keycloak_admin_password:
