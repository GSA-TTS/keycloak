#!/usr/bin/env bash

# USAI WebAuthn realm configuration
# Based on Keycloak WebAuthn Tutorial

REALM_NAME='usai-webauthn'

echo ""
echo "================================="
echo "Setting up realm $REALM_NAME..."
echo "================================="
echo ""

# Create the realm
createRealm $REALM_NAME

# Enable user registration
echo "Enabling user registration..."
$KCADM update realms/$REALM_NAME -s registrationAllowed=true

# Enable the storage of admin events including their representation
echo "Configuring admin events..."
$KCADM update events/config -r ${REALM_NAME} -s adminEventsEnabled=true -s adminEventsDetailsEnabled=true

# Enable the storage of login events and define the expiration of a stored login event
echo "Configuring login events..."
$KCADM update events/config -r ${REALM_NAME} -s eventsEnabled=true -s eventsExpiration=259200

# Define the login event types to be stored
echo "Configuring event types..."
$KCADM update events/config -r ${REALM_NAME} -s 'enabledEventTypes=["CLIENT_DELETE", "CLIENT_DELETE_ERROR", "CLIENT_INFO", "CLIENT_INFO_ERROR", "CLIENT_INITIATED_ACCOUNT_LINKING", "CLIENT_INITIATED_ACCOUNT_LINKING_ERROR", "CLIENT_LOGIN", "CLIENT_LOGIN_ERROR", "CLIENT_REGISTER", "CLIENT_REGISTER_ERROR", "CLIENT_UPDATE", "CLIENT_UPDATE_ERROR", "CODE_TO_TOKEN", "CODE_TO_TOKEN_ERROR", "CUSTOM_REQUIRED_ACTION", "CUSTOM_REQUIRED_ACTION_ERROR", "EXECUTE_ACTIONS", "EXECUTE_ACTIONS_ERROR", "EXECUTE_ACTION_TOKEN", "EXECUTE_ACTION_TOKEN_ERROR", "FEDERATED_IDENTITY_LINK", "FEDERATED_IDENTITY_LINK_ERROR", "GRANT_CONSENT", "GRANT_CONSENT_ERROR", "IDENTITY_PROVIDER_FIRST_LOGIN", "IDENTITY_PROVIDER_FIRST_LOGIN_ERROR", "IDENTITY_PROVIDER_LINK_ACCOUNT", "IDENTITY_PROVIDER_LINK_ACCOUNT_ERROR", "IDENTITY_PROVIDER_LOGIN", "IDENTITY_PROVIDER_LOGIN_ERROR", "IDENTITY_PROVIDER_POST_LOGIN", "IDENTITY_PROVIDER_POST_LOGIN_ERROR", "IDENTITY_PROVIDER_RESPONSE", "IDENTITY_PROVIDER_RESPONSE_ERROR", "IDENTITY_PROVIDER_RETRIEVE_TOKEN", "IDENTITY_PROVIDER_RETRIEVE_TOKEN_ERROR", "IMPERSONATE", "IMPERSONATE_ERROR", "INTROSPECT_TOKEN", "INTROSPECT_TOKEN_ERROR", "INVALID_SIGNATURE", "INVALID_SIGNATURE_ERROR", "LOGIN", "LOGIN_ERROR", "LOGOUT", "LOGOUT_ERROR", "PERMISSION_TOKEN", "PERMISSION_TOKEN_ERROR", "REFRESH_TOKEN", "REFRESH_TOKEN_ERROR", "REGISTER", "REGISTER_ERROR", "REGISTER_NODE", "REGISTER_NODE_ERROR", "REMOVE_FEDERATED_IDENTITY", "REMOVE_FEDERATED_IDENTITY_ERROR", "REMOVE_TOTP", "REMOVE_TOTP_ERROR", "RESET_PASSWORD", "RESET_PASSWORD_ERROR", "RESTART_AUTHENTICATION", "RESTART_AUTHENTICATION_ERROR", "REVOKE_GRANT", "REVOKE_GRANT_ERROR", "SEND_IDENTITY_PROVIDER_LINK", "SEND_IDENTITY_PROVIDER_LINK_ERROR", "SEND_RESET_PASSWORD", "SEND_RESET_PASSWORD_ERROR", "SEND_VERIFY_EMAIL", "SEND_VERIFY_EMAIL_ERROR", "TOKEN_EXCHANGE", "TOKEN_EXCHANGE_ERROR", "UNREGISTER_NODE", "UNREGISTER_NODE_ERROR", "UPDATE_CONSENT", "UPDATE_CONSENT_ERROR", "UPDATE_EMAIL", "UPDATE_EMAIL_ERROR", "UPDATE_PASSWORD", "UPDATE_PASSWORD_ERROR", "UPDATE_PROFILE", "UPDATE_PROFILE_ERROR", "UPDATE_TOTP", "UPDATE_TOTP_ERROR", "USER_INFO_REQUEST", "USER_INFO_REQUEST_ERROR", "VALIDATE_ACCESS_TOKEN", "VALIDATE_ACCESS_TOKEN_ERROR", "VERIFY_EMAIL", "VERIFY_EMAIL_ERROR"]'

# Create client for USAI
echo "Creating USAI client..."
CLIENT_ID=usai-client
ID=$(createClient $REALM_NAME $CLIENT_ID)
$KCADM update clients/$ID -r $REALM_NAME \
    -s name="USAI Client" \
    -s protocol=openid-connect \
    -s publicClient=true \
    -s standardFlowEnabled=true \
    -s 'redirectUris=["https://usai.gov/*", "http://localhost:*/*"]' \
    -s baseUrl="https://usai.gov/" \
    -s 'webOrigins=["*"]'

# Set account theme to use the new Account UI (if preview features are enabled)
echo "Setting account theme..."
$KCADM update realms/$REALM_NAME -s accountTheme="keycloak-preview"

# Set login theme to USAI theme
echo "Setting login theme to USAI..."
$KCADM update realms/$REALM_NAME -s loginTheme="usai"

#############
# WebAuthn authentication flow with nested subflows
#

echo "Configuring WebAuthn authentication flow..."

# Set browser flow back to default so we can delete our custom flow
$KCADM update realms/$REALM_NAME -s browserFlow=browser

# Create new WebAuthn flow
TOP_LEVEL_FLOW_NAME=Browser-WebAuthn-USAI
deleteTopLevelFlow $REALM_NAME $TOP_LEVEL_FLOW_NAME
createTopLevelFlow $REALM_NAME $TOP_LEVEL_FLOW_NAME

# Cookie authenticator for SSO
echo "Adding Cookie authenticator..."
createExecution $REALM_NAME $TOP_LEVEL_FLOW_NAME auth-cookie ALTERNATIVE

# Create subflow for all user interactions
echo "Creating Forms subflow..."
FORMS_SUBFLOW_NAME=Forms
createSubflow $REALM_NAME $TOP_LEVEL_FLOW_NAME $TOP_LEVEL_FLOW_NAME $FORMS_SUBFLOW_NAME ALTERNATIVE

# Username form
echo "Adding Username form..."
createExecution $REALM_NAME $FORMS_SUBFLOW_NAME auth-username-form REQUIRED

# Create subflow for passwordless or two-factor authentication
echo "Creating Passwordless or Two-factors subflow..."
PWD_OR_2FA_SUBFLOW_NAME="Passwordless_Or_Two-factors"
createSubflow $REALM_NAME "$TOP_LEVEL_FLOW_NAME" $FORMS_SUBFLOW_NAME "$PWD_OR_2FA_SUBFLOW_NAME" REQUIRED

# WebAuthn Passwordless authenticator
echo "Adding WebAuthn Passwordless authenticator..."
createExecution "$REALM_NAME" "$PWD_OR_2FA_SUBFLOW_NAME" webauthn-authenticator-passwordless ALTERNATIVE

# Create subflow for password and second factor
echo "Creating Password and Second-factor subflow..."
PWD_AND_2FA_SUBFLOW_NAME="Password_And_Second-factor"
createSubflow "$REALM_NAME" "$TOP_LEVEL_FLOW_NAME" "$PWD_OR_2FA_SUBFLOW_NAME" "$PWD_AND_2FA_SUBFLOW_NAME" ALTERNATIVE

# Password form
echo "Adding Password form..."
createExecution "$REALM_NAME" "$PWD_AND_2FA_SUBFLOW_NAME" auth-password-form REQUIRED

# Create subflow for second factor
echo "Creating Second-factor subflow..."
SECOND_FACTOR_SUBFLOW_NAME="Second-factor"
createSubflow "$REALM_NAME" "$TOP_LEVEL_FLOW_NAME" "$PWD_AND_2FA_SUBFLOW_NAME" "$SECOND_FACTOR_SUBFLOW_NAME" CONDITIONAL

# Conditional user configured authenticator
echo "Adding Conditional user configured authenticator..."
createExecution "$REALM_NAME" "$SECOND_FACTOR_SUBFLOW_NAME" conditional-user-configured REQUIRED

# WebAuthn authenticator for second factor
echo "Adding WebAuthn authenticator for second factor..."
createExecution "$REALM_NAME" "$SECOND_FACTOR_SUBFLOW_NAME" webauthn-authenticator ALTERNATIVE

# OTP form authenticator for second factor
echo "Adding OTP form authenticator for second factor..."
createExecution "$REALM_NAME" "$SECOND_FACTOR_SUBFLOW_NAME" auth-otp-form ALTERNATIVE

# Set the new flow as the browser flow
echo "Setting Browser-WebAuthn-USAI as the browser flow..."
$KCADM update realms/$REALM_NAME -s browserFlow=Browser-WebAuthn-USAI

#############
# Required Actions
#

echo "Configuring required actions..."

# Register WebAuthn required actions
registerRequiredAction $REALM_NAME "webauthn-register" "Webauthn Register"
registerRequiredAction $REALM_NAME "webauthn-register-passwordless" "Webauthn Register Passwordless"

# Set WebAuthn passwordless registration as default action for new users
echo "Setting WebAuthn passwordless as default required action..."
$KCADM update authentication/required-actions/webauthn-register-passwordless -r $REALM_NAME -s defaultAction=true

#############
# WebAuthn Policies
#

echo "Configuring WebAuthn policies..."

# Configure stronger requirements for passwordless authentication
$KCADM update realms/$REALM_NAME -s webAuthnPolicyPasswordlessUserVerificationRequirement=required

# Configure WebAuthn policy settings
$KCADM update realms/$REALM_NAME \
    -s webAuthnPolicyRpEntityName="USAI" \
    -s webAuthnPolicySignatureAlgorithms='["ES256", "RS256"]' \
    -s webAuthnPolicyRpId="usai.gov" \
    -s webAuthnPolicyAttestationConveyancePreference="not specified" \
    -s webAuthnPolicyAuthenticatorAttachment="not specified" \
    -s webAuthnPolicyRequireResidentKey="not specified" \
    -s webAuthnPolicyUserVerificationRequirement="not specified"

# Configure WebAuthn passwordless policy settings
$KCADM update realms/$REALM_NAME \
    -s webAuthnPolicyPasswordlessRpEntityName="USAI" \
    -s webAuthnPolicyPasswordlessSignatureAlgorithms='["ES256", "RS256"]' \
    -s webAuthnPolicyPasswordlessRpId="usai.gov" \
    -s webAuthnPolicyPasswordlessAttestationConveyancePreference="not specified" \
    -s webAuthnPolicyPasswordlessAuthenticatorAttachment="not specified" \
    -s webAuthnPolicyPasswordlessRequireResidentKey="not specified"

#############
# Users
#

echo "Creating test users..."

# Create test user with username/password
USER_NAME=testuser
USER_ID=$(createUser $REALM_NAME $USER_NAME)
$KCADM set-password -r $REALM_NAME --username $USER_NAME --new-password $USER_NAME
$KCADM update users/$USER_ID -r $REALM_NAME \
    -s firstName="Test" \
    -s lastName="User" \
    -s email="test.user@usai.gov" \
    -s emailVerified=true

echo ""
echo "================================="
echo "Realm $REALM_NAME configuration completed!"
echo "================================="
echo ""
echo "Summary:"
echo "- Realm: $REALM_NAME"
echo "- Client: $CLIENT_ID"
echo "- Test user: $USER_NAME (password: $USER_NAME)"
echo "- WebAuthn passwordless authentication enabled"
echo "- USAI login theme applied"
echo ""
echo "The test user will be required to set up a WebAuthn security key on first login."
echo ""
