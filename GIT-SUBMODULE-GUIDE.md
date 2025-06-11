# Setting Up Login.gov Integration as a Git Submodule

This guide provides instructions for setting up the Login.gov integration as a Git submodule in the Keycloak repository.

## What is a Git Submodule?

Git submodules allow you to keep a Git repository as a subdirectory of another Git repository. This lets you clone another repository into your project and keep your commits separate.

## Fixing the Current Issue

It appears that you're trying to add the Login.gov integration as a submodule, but the directory already exists in the Git index. Here's how to fix this:

1. First, remove the directory from the Git index (but keep the files):

```bash
git rm --cached -r keycloak-login.gov-integration
```

2. Remove any existing submodule configuration:

```bash
git config --remove-section submodule.keycloak-login.gov-integration 2>/dev/null || true
rm -rf .git/modules/keycloak-login.gov-integration 2>/dev/null || true
```

3. Delete the directory (make sure you have a backup if you've made changes):

```bash
rm -rf keycloak-login.gov-integration
```

4. Now add the submodule:

```bash
git submodule add https://github.com/GSA-TTS/keycloak-login.gov-integration keycloak-login.gov-integration
```

5. Initialize and update the submodule:

```bash
git submodule update --init --recursive
```

## Complete Setup Process

If you're starting from scratch, here's the complete process:

1. Clone the Keycloak repository:

```bash
git clone https://github.com/keycloak/keycloak.git
cd keycloak
```

2. Add the Login.gov integration as a submodule:

```bash
git submodule add https://github.com/GSA-TTS/keycloak-login.gov-integration keycloak-login.gov-integration
```

3. Initialize and update the submodule:

```bash
git submodule update --init --recursive
```

4. Add the module to the parent `pom.xml` if it's not already there:

```xml
<modules>
    <!-- ... other modules ... -->
    <module>quarkus</module>
    <module>keycloak-login.gov-integration</module>
</modules>
```

5. Commit the changes:

```bash
git add pom.xml .gitmodules keycloak-login.gov-integration
git commit -m "Add Login.gov integration as a submodule"
```

## Working with the Submodule

### Updating the Submodule

To update the submodule to the latest commit:

```bash
cd keycloak-login.gov-integration
git pull origin main
cd ..
git add keycloak-login.gov-integration
git commit -m "Update Login.gov integration submodule"
```

### Making Changes to the Submodule

If you need to make changes to the Login.gov integration:

1. Make your changes in the submodule directory
2. Commit and push those changes to the Login.gov integration repository
3. Update the submodule reference in the Keycloak repository

```bash
cd keycloak-login.gov-integration
# Make your changes
git add .
git commit -m "Your commit message"
git push origin main
cd ..
git add keycloak-login.gov-integration
git commit -m "Update Login.gov integration submodule"
```

## Building with the Submodule

To build Keycloak with the Login.gov integration submodule:

```bash
mvn clean install -DskipTests
```

## Docker Deployment with Submodule

The Docker setup will work the same way with the submodule. The `Dockerfile` and `docker-compose.yml` files remain unchanged.

## Notes for Maintainers

- When cloning the Keycloak repository, use `git clone --recursive` to automatically initialize and update all submodules
- When pulling changes, use `git pull && git submodule update --recursive` to update the submodules as well
