#!/bin/bash

# Script to update the Login.gov integration in the parent Keycloak repository
# This script should be run from the root of the Keycloak repository

set -e

echo "Updating Login.gov integration in Keycloak repository..."

# Check if keycloak-login.gov-integration directory exists
if [ ! -d "keycloak-login.gov-integration" ]; then
  echo "Error: keycloak-login.gov-integration directory not found!"
  echo "This script should be run from the root of the Keycloak repository."
  exit 1
fi

# Check if the directory is a Git submodule
IS_SUBMODULE=false
if [ -f ".gitmodules" ] && grep -q "keycloak-login.gov-integration" .gitmodules; then
  IS_SUBMODULE=true
  echo "Detected Login.gov integration as a Git submodule"
fi

# Update the submodule if it is one
if [ "$IS_SUBMODULE" = true ]; then
  echo "Updating Login.gov integration submodule..."
  git submodule update --init --recursive keycloak-login.gov-integration
  cd keycloak-login.gov-integration
  git checkout main
  git pull origin main
  cd ..
fi

# Check if the module is already in the parent pom.xml
if ! grep -q "<module>keycloak-login.gov-integration</module>" pom.xml; then
  echo "Adding keycloak-login.gov-integration module to parent pom.xml..."
  sed -i '' 's/<module>quarkus<\/module>/<module>quarkus<\/module>\n        <module>keycloak-login.gov-integration<\/module>/' pom.xml
fi

# Build the Login.gov integration
echo "Building Login.gov integration..."
cd keycloak-login.gov-integration
mvn clean install
cd ..

# Create providers directory in the Keycloak distribution
echo "Copying Login.gov integration to Keycloak distribution..."
mkdir -p quarkus/dist/target/keycloak-quarkus-server/providers
cp keycloak-login.gov-integration/target/login_gov-*.jar quarkus/dist/target/keycloak-quarkus-server/providers/

# Update the Keycloak distribution ZIP file
echo "Updating Keycloak distribution ZIP file..."
cd quarkus/dist/target
zip -r keycloak-*.zip keycloak-quarkus-server/providers

# Update the Keycloak distribution TAR.GZ file
echo "Updating Keycloak distribution TAR.GZ file..."
tar -czf keycloak-*.tar.gz keycloak-quarkus-server/providers
cd ../../..

# Commit changes if it's a submodule
if [ "$IS_SUBMODULE" = true ]; then
  echo "Committing submodule update..."
  git add keycloak-login.gov-integration
  git commit -m "Update Login.gov integration submodule" || echo "No changes to commit"
fi

echo "Login.gov integration has been successfully updated in the Keycloak repository!"
echo "The Login.gov extension JAR has been added to the Keycloak distribution."
echo ""
echo "To use the Login.gov identity provider:"
echo "1. Start Keycloak"
echo "2. Log in to the admin console"
echo "3. Go to Identity Providers"
echo "4. Add the Login.gov identity provider"
echo ""
echo "For Docker deployment, use the provided Dockerfile and docker-compose.yml files."
