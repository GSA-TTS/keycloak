#!/usr/bin/env bash

# Quick setup script for USAI WebAuthn configuration
# This script helps set up the environment and run the configuration

set -e

echo "================================="
echo "USAI WebAuthn Setup Script"
echo "================================="
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."

# Check for jq
if ! command_exists jq; then
    echo "❌ jq is not installed. Please install it first:"
    echo "   Ubuntu/Debian: sudo apt-get install jq"
    echo "   CentOS/RHEL: sudo yum install jq"
    echo "   macOS: brew install jq"
    exit 1
fi
echo "✅ jq is installed"

# Check for Docker (if using Docker setup)
if command_exists docker; then
    echo "✅ Docker is available"
    
    # Check if Keycloak container is running
    if docker ps | grep -q keycloak; then
        echo "✅ Keycloak container is running"
        KEYCLOAK_HOST="localhost"
    else
        echo "⚠️  Keycloak container not found. Make sure to start it with:"
        echo "   docker-compose up -d"
    fi
else
    echo "ℹ️  Docker not found - assuming standalone Keycloak installation"
fi

echo ""

# Set up environment variables
echo "Setting up environment variables..."

# Try to detect Keycloak installation
if [ -f "../keycloak-26.3.1/bin/kcadm.sh" ]; then
    KCADM_PATH="../keycloak-26.3.1/bin/kcadm.sh"
    echo "✅ Found Keycloak installation at ../keycloak-26.3.1/"
elif [ -f "/opt/keycloak/bin/kcadm.sh" ]; then
    KCADM_PATH="/opt/keycloak/bin/kcadm.sh"
    echo "✅ Found Keycloak installation at /opt/keycloak/"
else
    echo "⚠️  Could not auto-detect Keycloak installation"
    echo "Please set KCADM environment variable manually:"
    echo "export KCADM=/path/to/keycloak/bin/kcadm.sh"
    KCADM_PATH=""
fi

# Set environment variables
export KCADM="${KCADM:-$KCADM_PATH}"
export HOST_FOR_KCADM="${HOST_FOR_KCADM:-localhost}"
export KEYCLOAK_USER="${KEYCLOAK_USER:-admin}"
export KEYCLOAK_PASSWORD="${KEYCLOAK_PASSWORD:-admin}"

echo ""
echo "Environment variables:"
echo "KCADM=$KCADM"
echo "HOST_FOR_KCADM=$HOST_FOR_KCADM"
echo "KEYCLOAK_USER=$KEYCLOAK_USER"
echo "KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD"
echo ""

# Validate environment
if [ -z "$KCADM" ]; then
    echo "❌ KCADM not set. Please set it manually:"
    echo "export KCADM=/path/to/keycloak/bin/kcadm.sh"
    exit 1
fi

if [ ! -f "$KCADM" ]; then
    echo "❌ kcadm.sh not found at: $KCADM"
    echo "Please check the path and try again."
    exit 1
fi

echo "✅ Environment validation passed"
echo ""

# Test Keycloak connection
echo "Testing Keycloak connection..."
if timeout 10 curl -s "http://$HOST_FOR_KCADM:8080" > /dev/null; then
    echo "✅ Keycloak is accessible at http://$HOST_FOR_KCADM:8080"
else
    echo "❌ Cannot connect to Keycloak at http://$HOST_FOR_KCADM:8080"
    echo "Please make sure Keycloak is running and accessible."
    exit 1
fi

echo ""

# Ask user if they want to proceed
read -p "Do you want to run the WebAuthn configuration now? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Starting WebAuthn configuration..."
    echo "================================="
    
    # Run the main configuration script
    ./keycloak-configuration.sh
    
    echo ""
    echo "================================="
    echo "Setup completed successfully! 🎉"
    echo "================================="
    echo ""
    echo "Next steps:"
    echo "1. Access the Admin Console: http://$HOST_FOR_KCADM:8080/admin/"
    echo "2. Navigate to the 'usai-webauthn' realm"
    echo "3. Test login with user 'testuser' (password: 'testuser')"
    echo "4. Set up a WebAuthn security key when prompted"
    echo ""
    echo "For more information, see README.md"
else
    echo ""
    echo "Configuration skipped. You can run it later with:"
    echo "./keycloak-configuration.sh"
    echo ""
    echo "Make sure to export the environment variables first:"
    echo "export KCADM=$KCADM"
    echo "export HOST_FOR_KCADM=$HOST_FOR_KCADM"
    echo "export KEYCLOAK_USER=$KEYCLOAK_USER"
    echo "export KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD"
fi

echo ""
