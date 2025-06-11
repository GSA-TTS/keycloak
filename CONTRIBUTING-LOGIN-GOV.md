# Contributing the Login.gov Integration to Keycloak

This document provides instructions for contributing the Login.gov integration to the main Keycloak repository.

## Prerequisites

- Git
- Maven
- Java 17 or later

## Steps to Contribute

### 1. Fork the Keycloak Repository

1. Fork the Keycloak repository on GitHub: https://github.com/keycloak/keycloak

2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/keycloak.git
   cd keycloak
   ```

3. Add the upstream repository:
   ```bash
   git remote add upstream https://github.com/keycloak/keycloak.git
   ```

### 2. Create a Branch for the Login.gov Integration

```bash
git checkout -b add-login-gov-integration
```

### 3. Add the Login.gov Integration Module

1. Copy the `keycloak-login.gov-integration` directory to the root of the Keycloak repository:
   ```bash
   cp -r /path/to/keycloak-login.gov-integration .
   ```

2. Add the module to the parent `pom.xml`:
   ```xml
   <modules>
       <!-- ... other modules ... -->
       <module>quarkus</module>
       <module>keycloak-login.gov-integration</module>
   </modules>
   ```

### 4. Update the Login.gov Integration Code

Ensure the Login.gov integration code is compatible with the target Keycloak version:

1. Update the `pom.xml` in the `keycloak-login.gov-integration` directory:
   - Set the parent version to match the Keycloak version
   - Update dependencies as needed

2. Fix any compilation issues:
   - Update JAX-RS imports from `javax.ws.rs.*` to `jakarta.ws.rs.*`
   - Update method signatures to match the Keycloak API
   - Fix any other compatibility issues

### 5. Build and Test

1. Build the entire project:
   ```bash
   mvn clean install -DskipTests
   ```

2. Test the Login.gov integration:
   - Start Keycloak
   - Configure the Login.gov identity provider
   - Test authentication with Login.gov

### 6. Commit and Push Changes

1. Commit your changes:
   ```bash
   git add .
   git commit -m "Add Login.gov identity provider integration"
   ```

2. Push to your fork:
   ```bash
   git push origin add-login-gov-integration
   ```

### 7. Create a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your branch and create the pull request
4. Provide a detailed description of the changes
5. Follow the Keycloak contribution guidelines

## Maintaining the Integration

To keep the Login.gov integration up to date with Keycloak:

1. Regularly pull changes from upstream:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. Merge the changes into your integration branch:
   ```bash
   git checkout add-login-gov-integration
   git merge main
   ```

3. Resolve any conflicts and update the code as needed

4. Build and test the integration

5. Push the updated branch to your fork

## Notes for Keycloak Maintainers

When reviewing the Login.gov integration:

1. Ensure it follows Keycloak coding standards
2. Verify it works with the current Keycloak version
3. Check for security issues
4. Test with Login.gov sandbox environment
5. Consider adding automated tests

## Docker Deployment

For Docker deployment, use the provided `Dockerfile` and `docker-compose.yml` files.
