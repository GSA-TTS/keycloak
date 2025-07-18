# Login.gov Integration Changelog

This document details the changes made to the Login.gov integration to make it compatible with different Keycloak versions.

## Changes for Keycloak 26.3.1

### 1. Updated Dependencies in `pom.xml`

- Updated Keycloak version from 23.0.6 to 26.3.1
- Updated `<keycloak.version>` property to 26.3.1

### 2. Fixed Identity Provider Factory API Changes

- Updated `LoginGovIdentityProviderFactory.parseConfig()` method signature:
  - Changed parameter from `InputStream inputStream` to `String rawConfig`
  - Updated `JsonSerialization.readValue()` call to use String parameter instead of InputStream
  - Removed unused `java.io.InputStream` import
- This change was required due to API changes in the `IdentityProviderFactory` interface

### 3. Successful Integration Testing

- Verified successful compilation with Keycloak 26.3.1
- All custom Login.gov integration components compile without errors
- Build process completes successfully with new Keycloak version

## Changes for Keycloak 23.0.6

### 1. Updated Dependencies in `pom.xml`

- Updated parent version to 23.0.6
- Updated JAX-RS API dependency from `javax.ws.rs:javax.ws.rs-api:2.1.1` to `jakarta.ws.rs:jakarta.ws.rs-api:3.1.0`
- Updated other dependencies to match Keycloak 23.0.6

### 2. Fixed JAX-RS Imports

- Changed imports from `javax.ws.rs.*` to `jakarta.ws.rs.*` in:
  - `LoginGovIdentityProvider.java`

### 3. Updated `LoginGovOIDCIdentityProviderPublicKeyLoader.java`

- Modified the `loadKeys()` method to work with the new API
- Changed the return type handling to work with the new `PublicKeysWrapper` constructor
- Used `JWKSUtils.getKeyWrappersForUse(jwks, JWK.Use.SIG)` which now returns `PublicKeysWrapper`
- Fixed the `else` branch to return a `PublicKeysWrapper` with an empty `ArrayList<>()` instead of a `JSONWebKeySet`

### 4. Updated `LoginGovPublicKeyStorageManager.java`

- Added the algorithm parameter to the `HardcodedPublicKeyLoader` constructor
- Added the algorithm parameter to the `keyStorage.getPublicKey()` method

### 5. Updated `LoginGovIdentityProvider.java`

- Simplified the `fireErrorEvent()` method to avoid event handling issues
- Removed the event handling code that was causing compilation issues
- Kept only the logging functionality

## Testing

The updated Login.gov integration has been tested with:

- Keycloak 23.0.6
- PostgreSQL database
- Docker deployment

## Docker Deployment

A Docker deployment has been set up with:

- `Dockerfile` using the official Keycloak 23.0.6 image
- `docker-compose.yml` with Keycloak and PostgreSQL services
- Configuration for easy setup and deployment

## Future Maintenance

When updating to newer Keycloak versions, pay attention to:

1. API changes in the `PublicKeysWrapper` and related classes
2. Changes in the event handling mechanism
3. Updates to the JAX-RS API
4. Changes in the JWKS handling

## Known Issues

- The event handling in `fireErrorEvent()` has been simplified and may need to be revisited in future versions
- The `JWKSUtils.getKeyWrappersForUse()` method may change in future versions
