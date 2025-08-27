# WebAuthn Theme Implementation for USAI Keycloak

This document describes the WebAuthn support that has been added to the USAI theme for Keycloak.

## Overview

The USAI theme has been updated to support WebAuthn authentication, including:
- Passwordless authentication with security keys/passkeys
- Conditional UI for passkeys (autofill suggestions)
- Security key registration and management
- Fallback to username/password authentication
- Integration with existing Login.gov identity providers

## Files Added/Modified

### New WebAuthn Templates

1. **`webauthn-authenticate.ftl`** - Security key authentication page
   - Displays available security keys
   - Handles WebAuthn authentication flow
   - USAI-styled with government design system components

2. **`webauthn-register.ftl`** - Security key registration page
   - Guides users through security key registration
   - Provides helpful instructions and alerts
   - Supports cancellation for app-initiated actions

3. **`webauthn-error.ftl`** - WebAuthn error handling page
   - User-friendly error messages
   - Technical details in collapsible section
   - Retry and navigation options

4. **`passkeys.ftl`** - Passkey conditional UI support
   - Enables passkey autofill in username field
   - Provides manual passkey authentication button
   - Helpful tips for users

5. **`login-username.ftl`** - Username form with WebAuthn support
   - Username field with passkey autocomplete
   - Integrates conditional WebAuthn UI
   - Maintains USAI styling

### Modified Templates

6. **`login.ftl`** - Updated main login form
   - Now includes username/password fields
   - Supports WebAuthn conditional UI
   - Maintains social provider integration
   - Added passkey support

### Styling and Messages

7. **`usai.css`** - Enhanced with WebAuthn styles
   - WebAuthn authenticator list styling
   - Passkey option styling
   - USA Design System button variants
   - Responsive WebAuthn components
   - Error and alert styling

8. **`messages_en.properties`** - WebAuthn message strings
   - All WebAuthn-related messages
   - User-friendly error messages
   - Consistent terminology

## Features Implemented

### 1. Passwordless Authentication
- Users can authenticate using only their security key/passkey
- No username/password required for registered users
- Supports platform authenticators (Touch ID, Face ID, Windows Hello)
- Supports roaming authenticators (YubiKey, etc.)

### 2. Conditional UI (Passkeys)
- Passkey suggestions appear when clicking in username field
- Automatic detection of available passkeys
- Seamless user experience
- Fallback to manual authentication

### 3. Security Key Registration
- Step-by-step registration process
- Support for multiple security keys per user
- User-friendly naming of security keys
- Registration date tracking

### 4. Multi-Factor Authentication
- WebAuthn as second factor after password
- Flexible authentication flows
- Conditional requirements based on user setup

### 5. Error Handling
- Comprehensive error messages
- Technical details for troubleshooting
- Graceful fallbacks
- User guidance for common issues

## Authentication Flows Supported

### Flow 1: Initial Authentication (Required)
1. User selects identity provider (Login.gov, etc.)
2. External authentication through provider
3. User authenticated and logged in
4. Optional: WebAuthn registration prompt (required action)

### Flow 2: Passwordless Return Authentication
1. User enters username (for existing users with registered security keys)
2. WebAuthn challenge presented
3. User authenticates with security key
4. Access granted (no provider authentication needed)

### Flow 3: WebAuthn Conditional UI (Passkeys)
1. User clicks in username field
2. Passkey suggestions appear (if available)
3. User selects passkey
4. Automatic authentication

### Flow 4: WebAuthn Registration (Post-Authentication)
1. User completes initial provider authentication
2. Keycloak presents WebAuthn registration as required action
3. User registers security key/passkey
4. Future logins can use passwordless authentication

## Browser Compatibility

### Fully Supported
- **Chrome/Chromium 67+** - Full WebAuthn support
- **Firefox 60+** - Full WebAuthn support
- **Safari 14+** - WebAuthn support (limited platform authenticators)
- **Edge 18+** - Full WebAuthn support

### Platform Authenticator Support
- **Windows** - Windows Hello (fingerprint, face, PIN)
- **macOS** - Touch ID, Face ID
- **iOS** - Face ID, Touch ID
- **Android** - Fingerprint, face unlock

### External Authenticator Support
- **YubiKey** - All FIDO2/WebAuthn compatible models
- **Google Titan** - Security keys
- **Other FIDO2** - Any CTAP2 compatible authenticator

## Security Considerations

### WebAuthn Security Benefits
- **Phishing Resistant** - Cryptographic binding to domain
- **No Shared Secrets** - Public key cryptography
- **Replay Attack Prevention** - Challenge-response protocol
- **User Verification** - Biometric or PIN verification

### Implementation Security
- **User Verification Required** - For passwordless authentication
- **Relying Party ID** - Bound to `usai.gov` domain
- **Signature Algorithms** - ES256, RS256 supported
- **Attestation** - Optional attestation verification

## Configuration Requirements

### Keycloak Server Configuration
The WebAuthn realm must be configured with:

```bash
# WebAuthn Policies
webAuthnPolicyRpEntityName=USAI
webAuthnPolicyRpId=usai.gov
webAuthnPolicyPasswordlessUserVerificationRequirement=required
webAuthnPolicySignatureAlgorithms=["ES256", "RS256"]
```

### Authentication Flow
The realm should use the `Browser-WebAuthn-USAI` authentication flow:
- Cookie (SSO)
- Username Form
- Passwordless OR Password + 2FA subflow

### Required Actions
- `webauthn-register-passwordless` - Set as default for new users
- `webauthn-register` - Available for second factor setup

## User Experience

### First-Time Users
1. Sign in through identity provider (Login.gov, etc.)
2. Complete external authentication
3. Prompted to register security key (required action)
4. Follow registration wizard with USAI-styled interface
5. Future logins can use passwordless authentication

### Returning Users with Security Keys
1. Enter username or use passkey autofill
2. Authenticate with security key
3. Immediate access (no provider authentication needed)

### Returning Users without Security Keys
1. Sign in through identity provider (Login.gov, etc.)
2. Complete external authentication
3. Access granted

### Fallback Options
- Identity provider authentication always available
- Multiple security keys supported per user
- Account recovery through identity provider
- Admin can reset WebAuthn credentials if needed

## Testing and Validation

### Test Scenarios
1. **Passwordless Registration** - New user security key setup
2. **Passwordless Authentication** - Existing user login
3. **Conditional UI** - Passkey autofill functionality
4. **Error Handling** - Various failure scenarios
5. **Multi-Device** - Cross-device compatibility
6. **Fallback Authentication** - Password-based login

### Browser Testing
- Test in all supported browsers
- Verify platform authenticator functionality
- Test external security key support
- Validate responsive design

## Deployment Notes

### Production Considerations
1. **HTTPS Required** - WebAuthn requires secure context
2. **Domain Configuration** - Update RP ID for production domain
3. **User Training** - Provide user education materials
4. **Support Documentation** - Create troubleshooting guides

### Monitoring and Analytics
- Track WebAuthn registration rates
- Monitor authentication success/failure rates
- Analyze user adoption patterns
- Identify common error scenarios

## Troubleshooting

### Common Issues
1. **Browser Not Supported** - Upgrade browser or use alternative
2. **Security Key Not Recognized** - Check FIDO2 compatibility
3. **Registration Fails** - Verify user verification capability
4. **Authentication Timeout** - Increase timeout settings

### Debug Information
- Browser console logs for WebAuthn API calls
- Keycloak server logs for authentication events
- Network inspection for WebAuthn requests
- User agent and capability detection

## Future Enhancements

### Potential Improvements
1. **Resident Key Support** - Enhanced passwordless experience
2. **Attestation Verification** - Security key validation
3. **Backup Codes** - Alternative recovery method
4. **Admin Management** - Security key administration tools
5. **Analytics Dashboard** - WebAuthn usage metrics

### Integration Opportunities
1. **Mobile App Integration** - Native Web
