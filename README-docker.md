# Dockerized Keycloak with Login.gov Integration

This repository contains a dockerized version of Keycloak with the Login.gov identity provider extension.

## Prerequisites

- Docker
- Docker Compose

## Building and Running

1. Build the Login.gov extension:

```bash
cd keycloak-login.gov-integration
mvn clean install
cd ..
```

2. Start Keycloak with Docker Compose:

```bash
docker-compose up -d
```

3. Access Keycloak at http://localhost:8080

4. Log in to the admin console with:
   - Username: admin
   - Password: admin

## Configuring the Login.gov Identity Provider

1. Log in to the Keycloak admin console
2. Select your realm (or create a new one)
3. Go to Identity Providers
4. Click "Add provider" and select "Login.gov"
5. Configure the following settings:
   - Alias: login-gov
   - Display Name: Login.gov
   - Authorization URL: https://idp.int.identitysandbox.gov/openid_connect/authorize
   - Token URL: https://idp.int.identitysandbox.gov/api/openid_connect/token
   - JWKS URL: https://idp.int.identitysandbox.gov/api/openid_connect/certs
   - Client ID: Your Login.gov client ID
   - Client Secret: Your Login.gov client secret
   - ACR Values: http://idmanagement.gov/ns/assurance/ial/1
   - Deep Logout: true (if you want users to be logged out of Login.gov when they log out of Keycloak)

6. Save the configuration

## Building a Custom Docker Image

If you want to build a custom Docker image with the Login.gov extension:

```bash
docker build -t keycloak-login-gov .
```

## Notes

- The Docker Compose setup uses PostgreSQL as the database
- The Keycloak instance is started in development mode for easier testing
- For production use, you should modify the configuration to use HTTPS and other security best practices
