#!/usr/bin/env bash

# WebAuthn Configuration Script for Keycloak Realms
# Based on Keycloak WebAuthn Tutorial
# This script configures WebAuthn authentication for any specified realm

set -e

# Configuration variables
KEYCLOAK_HOME=${KEYCLOAK_HOME:-"/opt/keycloak"}
KCADM="${KEYCLOAK_HOME}/bin/kcadm.sh"
HOST_FOR_KCADM=${HOST_FOR_KCADM:-"localhost:8080"}
KEYCLOAK_USER=${KEYCLOAK_USER:-"admin"}
KEYCLOAK_PASSWORD=${KEYCLOAK_PASSWORD:-"admin"}

# Function to check if realm exists
realmExists() {
    local realm_name=$1
    $KCADM get realms/$realm_name >/dev/null 2>&1
}

# Function to create top-level flow
createTopLevelFlow() {
    local realm_name=$1
    local flow_name=$2
    echo "Creating top-level flow: $flow_name"
    $KCADM create authentication/flows -r $realm_name -s alias="$flow_name" -s providerId=basic-flow -s topLevel=true -s builtIn=false
}

# Function to delete top-level flow
deleteTopLevelFlow() {
    local realm_name=$1
    local flow_name=$2
    echo "Deleting flow: $flow_name (if exists)"
    local flow_id=$($KCADM get authentication/flows -r $realm_name --fields id,alias | jq -r ".[] | select(.alias==\"$flow_name\") | .id" 2>/dev/null || echo "")
    if [ -n "$flow_id" ]; then
        $KCADM delete authentication/flows/$flow_id -r $realm_name
    fi
}

# Function to create subflow
createSubflow() {
    local realm_name=$1
    local parent_flow=$2
    local subflow_name=$3
    local requirement=$4
    echo "Creating subflow: $subflow_name under $parent_flow"
    $KCADM create authentication/flows -r $realm_name -s alias="$subflow_name" -s providerId=basic-flow -s topLevel=false -s builtIn=false
    local execution_id=$($KCADM create authentication/flows/$parent_flow/executions/flow -r $realm_name -s flowAlias="$subflow_name" -i)
    $KCADM update authentication/flows/$parent_flow/executions -r $realm_name -s id=$execution_id -s requirement=$requirement
}

# Function to create execution
createExecution() {
    local realm_name=$1
    local flow_name=$2
    local provider=$3
    local requirement=$4
    echo "Creating execution: $provider in $flow_name"
    local execution_id=$($KCADM create authentication/flows/$flow_name/executions/execution -r $realm_name -s provider="$provider" -i)
    $KCADM update authentication/flows/$flow_name/executions -r $realm_name -s id=$execution_id -s requirement=$requirement
}

# Function to register required action
registerRequiredAction() {
    local realm_name=$1
    local provider_id=$2
    local name=$3
    echo "Registering required action: $name"
    $KCADM create authentication/register-required-action -r $realm_name -s providerId="$provider_id" -s name="$name"
}

# Main configuration function
configureWebAuthnForRealm() {
    local realm_name=$1
    
    echo ""
    echo "================================="
    echo "Configuring WebAuthn for realm: $realm_name"
    echo "================================="
    echo ""
    
    # Check if realm exists
    if ! realmExists $realm_name; then
        echo "Error: Realm '$realm_name' does not exist!"
        exit 1
    fi
    
    # Authenticate with Keycloak
    echo "Authenticating with Keycloak..."
    $KCADM config credentials --server http://$HOST_FOR_KCADM --realm master --user $KEYCLOAK_USER --password $KEYCLOAK_PASSWORD
    
    echo "Setting up WebAuthn authentication flow..."
    
    # Set browser flow back to default so we can delete our custom flow
    $KCADM update realms/$realm_name -s browserFlow=browser
    
    # Create WebAuthn authentication flow
    TOP_LEVEL_FLOW_NAME="Browser-WebAuthn-USAI"
    deleteTopLevelFlow $realm_name $TOP_LEVEL_FLOW_NAME
    createTopLevelFlow $realm_name $TOP_LEVEL_FLOW_NAME
    
    # Cookie (for SSO)
    createExecution $realm_name $TOP_LEVEL_FLOW_NAME auth-cookie ALTERNATIVE
    
    # Create subflow for all user interactions
    FORMS_SUBFLOW_NAME="Forms"
    createSubflow $realm_name $TOP_LEVEL_FLOW_NAME $FORMS_SUBFLOW_NAME ALTERNATIVE
    
    # Username form
    createExecution $realm_name $FORMS_SUBFLOW_NAME auth-username-form REQUIRED
    
    # Create subflow for passwordless or two-factor
    PWD_OR_2FA_SUBFLOW_NAME="Passwordless_Or_Two-factors"
    createSubflow $realm_name $FORMS_SUBFLOW_NAME $PWD_OR_2FA_SUBFLOW_NAME REQUIRED
    
    # WebAuthn Passwordless
    createExecution $realm_name $PWD_OR_2FA_SUBFLOW_NAME webauthn-authenticator-passwordless ALTERNATIVE
    
    # Create subflow for password and second factor
    PWD_AND_2FA_SUBFLOW_NAME="Password_And_Second-factor"
    createSubflow $realm_name $PWD_OR_2FA_SUBFLOW_NAME $PWD_AND_2FA_SUBFLOW_NAME ALTERNATIVE
    
    # Password form
    createExecution $realm_name $PWD_AND_2FA_SUBFLOW_NAME auth-password-form REQUIRED
    
    # Create subflow for second factor
    SECOND_FACTOR_SUBFLOW_NAME="Second-factor"
    createSubflow $realm_name $PWD_AND_2FA_SUBFLOW_NAME $SECOND_FACTOR_SUBFLOW_NAME CONDITIONAL
    
    # Conditional user configured
    createExecution $realm_name $SECOND_FACTOR_SUBFLOW_NAME conditional-user-configured REQUIRED
    
    # WebAuthn second factor
    createExecution $realm_name $SECOND_FACTOR_SUBFLOW_NAME webauthn-authenticator ALTERNATIVE
    
    # OTP second factor
    createExecution $realm_name $SECOND_FACTOR_SUBFLOW_NAME auth-otp-form ALTERNATIVE
    
    # Set the new flow as the browser flow
    echo "Setting Browser-WebAuthn-USAI as the browser flow..."
    $KCADM update realms/$realm_name -s browserFlow=Browser-WebAuthn-USAI
    
    # Register required actions
    echo "Registering WebAuthn required actions..."
    registerRequiredAction $realm_name "webauthn-register" "Webauthn Register"
    registerRequiredAction $realm_name "webauthn-register-passwordless" "Webauthn Register Passwordless"
    
    # Set passwordless registration as default for new users
    echo "Setting WebAuthn passwordless registration as default required action..."
    $KCADM update authentication/required-actions/webauthn-register-passwordless -r $realm_name -s defaultAction=true
    
    # Configure WebAuthn policies
    echo "Configuring WebAuthn policies..."
    $KCADM update realms/$realm_name -s webAuthnPolicyPasswordlessUserVerificationRequirement=required
    $KCADM update realms/$realm_name -s webAuthnPolicyRpEntityName="USAI"
    $KCADM update realms/$realm_name -s webAuthnPolicyRpId="usai.gov"
    $KCADM update realms/$realm_name -s 'webAuthnPolicySignatureAlgorithms=["ES256", "RS256"]'
    
    echo ""
    echo "WebAuthn configuration completed successfully for realm: $realm_name"
    echo "Users will be prompted to register a security key on their next login."
    echo ""
}

# Script usage
usage() {
    echo "Usage: $0 <realm-name>"
    echo "Example: $0 myrealm"
    echo ""
    echo "Environment variables:"
    echo "  KEYCLOAK_HOME     - Path to Keycloak installation (default: /opt/keycloak)"
    echo "  HOST_FOR_KCADM    - Keycloak host:port (default: localhost:8080)"
    echo "  KEYCLOAK_USER     - Admin username (default: admin)"
    echo "  KEYCLOAK_PASSWORD - Admin password (default: admin)"
}

# Main script execution
if [ $# -eq 0 ]; then
    echo "Error: Realm name is required"
    usage
    exit 1
fi

REALM_NAME=$1

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq first."
    exit 1
fi

# Run the configuration
configureWebAuthnForRealm $REALM_NAME
