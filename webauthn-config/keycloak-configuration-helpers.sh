#!/usr/bin/env bash

# Helper functions for Keycloak configuration
# Based on Keycloak WebAuthn Tutorial

# Create a new realm
createRealm() {
    local realm_name=$1
    echo "Creating realm: $realm_name"
    $KCADM create realms -s realm=$realm_name -s enabled=true
}

# Create a new client and return its ID
createClient() {
    local realm_name=$1
    local client_id=$2
    echo "Creating client: $client_id in realm: $realm_name"
    
    # Create client and capture the ID from the response
    local response=$($KCADM create clients -r $realm_name -s clientId=$client_id -s enabled=true -i)
    echo $response
}

# Create a new user and return its ID
createUser() {
    local realm_name=$1
    local username=$2
    echo "Creating user: $username in realm: $realm_name"
    
    # Create user and capture the ID from the response
    local response=$($KCADM create users -r $realm_name -s username=$username -s enabled=true -i)
    echo $response
}

# Delete a top-level authentication flow
deleteTopLevelFlow() {
    local realm_name=$1
    local flow_name=$2
    echo "Deleting authentication flow: $flow_name in realm: $realm_name"
    
    # Get flow ID and delete if exists
    local flow_id=$($KCADM get authentication/flows -r $realm_name --fields id,alias | jq -r ".[] | select(.alias==\"$flow_name\") | .id" 2>/dev/null || echo "")
    if [[ -n "$flow_id" ]]; then
        $KCADM delete authentication/flows/$flow_id -r $realm_name
        echo "Deleted flow: $flow_name"
    else
        echo "Flow $flow_name does not exist, skipping deletion"
    fi
}

# Create a top-level authentication flow
createTopLevelFlow() {
    local realm_name=$1
    local flow_name=$2
    echo "Creating top-level authentication flow: $flow_name in realm: $realm_name"
    
    $KCADM create authentication/flows -r $realm_name -s alias=$flow_name -s description="WebAuthn Browser Flow" -s providerId=basic-flow -s topLevel=true -s builtIn=false
}

# Create a subflow
createSubflow() {
    local realm_name=$1
    local top_level_flow=$2
    local parent_flow=$3
    local subflow_name=$4
    local requirement=$5
    
    echo "Creating subflow: $subflow_name under $parent_flow with requirement: $requirement"
    
    # Create the subflow
    $KCADM create authentication/flows -r $realm_name -s alias="$subflow_name" -s description="$subflow_name subflow" -s providerId=basic-flow -s topLevel=false -s builtIn=false
    
    # Add the subflow as an execution to the parent flow
    local parent_flow_id=$($KCADM get authentication/flows -r $realm_name --fields id,alias | jq -r ".[] | select(.alias==\"$parent_flow\") | .id")
    $KCADM create authentication/flows/$parent_flow_id/executions/flow -r $realm_name -s alias="$subflow_name" -s requirement=$requirement
}

# Create an execution
createExecution() {
    local realm_name=$1
    local flow_name=$2
    local provider=$3
    local requirement=$4
    
    echo "Creating execution: $provider in flow: $flow_name with requirement: $requirement"
    
    # Get flow ID
    local flow_id=$($KCADM get authentication/flows -r $realm_name --fields id,alias | jq -r ".[] | select(.alias==\"$flow_name\") | .id")
    
    # Create execution
    $KCADM create authentication/flows/$flow_id/executions/execution -r $realm_name -s provider=$provider -s requirement=$requirement
}

# Register a required action
registerRequiredAction() {
    local realm_name=$1
    local provider_id=$2
    local name=$3
    
    echo "Registering required action: $name ($provider_id) in realm: $realm_name"
    
    # Check if already registered
    local existing=$($KCADM get authentication/required-actions -r $realm_name | jq -r ".[] | select(.providerId==\"$provider_id\") | .providerId" 2>/dev/null || echo "")
    
    if [[ -z "$existing" ]]; then
        $KCADM create authentication/register-required-action -r $realm_name -s providerId=$provider_id -s name="$name"
        echo "Registered required action: $name"
    else
        echo "Required action $name already registered"
    fi
}

# Check if jq is available
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq to continue."
        echo "On Ubuntu/Debian: sudo apt-get install jq"
        echo "On CentOS/RHEL: sudo yum install jq"
        echo "On macOS: brew install jq"
        exit 1
    fi
}

# Initialize - check dependencies
check_jq
