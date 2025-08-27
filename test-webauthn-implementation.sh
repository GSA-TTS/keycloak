#!/bin/bash

# WebAuthn Implementation Test Script
# This script tests the USAI theme WebAuthn implementation

set -e

echo "🔐 Testing WebAuthn Implementation for USAI Theme"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

echo "1. Checking WebAuthn Template Files..."
echo "-------------------------------------"

# Check if all required template files exist
templates=(
    "themes/src/main/resources/theme/usai/login/webauthn-authenticate.ftl"
    "themes/src/main/resources/theme/usai/login/webauthn-register.ftl"
    "themes/src/main/resources/theme/usai/login/webauthn-error.ftl"
    "themes/src/main/resources/theme/usai/login/passkeys.ftl"
    "themes/src/main/resources/theme/usai/login/password-commons.ftl"
    "themes/src/main/resources/theme/usai/login/login.ftl"
    "themes/src/main/resources/theme/usai/login/login-username.ftl"
    "themes/src/main/resources/theme/usai/login/login-password.ftl"
)

for template in "${templates[@]}"; do
    if [ -f "$template" ]; then
        print_test_result "Template exists: $(basename $template)" "PASS"
    else
        print_test_result "Template exists: $(basename $template)" "FAIL"
    fi
done

echo ""
echo "2. Checking WebAuthn JavaScript Files..."
echo "----------------------------------------"

# Check if all required JavaScript files exist
js_files=(
    "themes/src/main/resources/theme/usai/login/resources/js/webauthnAuthenticate.js"
    "themes/src/main/resources/theme/usai/login/resources/js/passkeysConditionalAuth.js"
    "themes/src/main/resources/theme/usai/login/resources/js/webauthnRegister.js"
)

for js_file in "${js_files[@]}"; do
    if [ -f "$js_file" ]; then
        print_test_result "JavaScript file exists: $(basename $js_file)" "PASS"
        
        # Check if file contains required functions
        case "$(basename $js_file)" in
            "webauthnAuthenticate.js")
                if grep -q "export.*authenticateByWebAuthn" "$js_file" && grep -q "export.*returnSuccess" "$js_file"; then
                    print_test_result "WebAuthn authenticate functions present" "PASS"
                else
                    print_test_result "WebAuthn authenticate functions present" "FAIL"
                fi
                ;;
            "passkeysConditionalAuth.js")
                if grep -q "export.*initAuthenticate" "$js_file"; then
                    print_test_result "Passkeys conditional auth functions present" "PASS"
                else
                    print_test_result "Passkeys conditional auth functions present" "FAIL"
                fi
                ;;
            "webauthnRegister.js")
                if grep -q "export.*registerByWebAuthn" "$js_file"; then
                    print_test_result "WebAuthn register functions present" "PASS"
                else
                    print_test_result "WebAuthn register functions present" "FAIL"
                fi
                ;;
        esac
    else
        print_test_result "JavaScript file exists: $(basename $js_file)" "FAIL"
    fi
done

echo ""
echo "3. Checking WebAuthn Messages..."
echo "--------------------------------"

messages_file="themes/src/main/resources/theme/usai/login/messages/messages_en.properties"
if [ -f "$messages_file" ]; then
    print_test_result "Messages file exists" "PASS"
    
    # Check for required WebAuthn messages
    required_messages=(
        "webauthn-login-title"
        "webauthn-registration-title"
        "webauthn-error-title"
        "webauthn-doAuthenticate"
        "webauthn-available-authenticators"
        "passkey-unsupported-browser-text"
        "doRegisterSecurityKey"
        "logoutOtherSessions"
    )
    
    for message in "${required_messages[@]}"; do
        if grep -q "^$message=" "$messages_file"; then
            print_test_result "Message exists: $message" "PASS"
        else
            print_test_result "Message exists: $message" "FAIL"
        fi
    done
else
    print_test_result "Messages file exists" "FAIL"
fi

echo ""
echo "4. Checking CSS WebAuthn Styles..."
echo "----------------------------------"

css_file="themes/src/main/resources/theme/usai/login/resources/css/usai.css"
if [ -f "$css_file" ]; then
    print_test_result "CSS file exists" "PASS"
    
    # Check for WebAuthn-specific CSS classes
    webauthn_classes=(
        "webauthn-authenticators"
        "webauthn-authenticator-item"
        "webauthn-passkey-option"
        "webauthn-registration-info"
        "webauthn-error-details"
    )
    
    for class in "${webauthn_classes[@]}"; do
        if grep -q "\.$class" "$css_file"; then
            print_test_result "CSS class exists: $class" "PASS"
        else
            print_test_result "CSS class exists: $class" "FAIL"
        fi
    done
else
    print_test_result "CSS file exists" "FAIL"
fi

echo ""
echo "5. Checking Template Integration..."
echo "----------------------------------"

# Check if templates properly import and use WebAuthn components
if [ -f "themes/src/main/resources/theme/usai/login/webauthn-authenticate.ftl" ]; then
    if grep -q "webauthnAuthenticate.js" "themes/src/main/resources/theme/usai/login/webauthn-authenticate.ftl"; then
        print_test_result "WebAuthn authenticate template imports JS" "PASS"
    else
        print_test_result "WebAuthn authenticate template imports JS" "FAIL"
    fi
fi

if [ -f "themes/src/main/resources/theme/usai/login/webauthn-register.ftl" ]; then
    if grep -q "webauthnRegister.js" "themes/src/main/resources/theme/usai/login/webauthn-register.ftl"; then
        print_test_result "WebAuthn register template imports JS" "PASS"
    else
        print_test_result "WebAuthn register template imports JS" "FAIL"
    fi
fi

if [ -f "themes/src/main/resources/theme/usai/login/passkeys.ftl" ]; then
    if grep -q "passkeysConditionalAuth.js" "themes/src/main/resources/theme/usai/login/passkeys.ftl"; then
        print_test_result "Passkeys template imports conditional auth JS" "PASS"
    else
        print_test_result "Passkeys template imports conditional auth JS" "FAIL"
    fi
fi

# Check if login templates include passkeys integration
if [ -f "themes/src/main/resources/theme/usai/login/login.ftl" ]; then
    if grep -q "passkeys.conditionalUIData" "themes/src/main/resources/theme/usai/login/login.ftl"; then
        print_test_result "Login template includes passkeys integration" "PASS"
    else
        print_test_result "Login template includes passkeys integration" "FAIL"
    fi
fi

if [ -f "themes/src/main/resources/theme/usai/login/login-username.ftl" ]; then
    if grep -q "passkeys.conditionalUIData" "themes/src/main/resources/theme/usai/login/login-username.ftl"; then
        print_test_result "Login-username template includes passkeys integration" "PASS"
    else
        print_test_result "Login-username template includes passkeys integration" "FAIL"
    fi
fi

echo ""
echo "6. Checking Build Compatibility..."
echo "---------------------------------"

# Test if the theme builds successfully
if cd themes && mvn clean compile -q > /dev/null 2>&1; then
    print_test_result "Theme builds successfully" "PASS"
else
    print_test_result "Theme builds successfully" "FAIL"
fi

cd ..

echo ""
echo "7. Browser Compatibility Check..."
echo "--------------------------------"

# Check if JavaScript uses modern browser APIs correctly
js_auth_file="themes/src/main/resources/theme/usai/login/resources/js/webauthnAuthenticate.js"
if [ -f "$js_auth_file" ]; then
    if grep -q "window.PublicKeyCredential" "$js_auth_file" && grep -q "navigator.credentials.get" "$js_auth_file"; then
        print_test_result "Uses correct WebAuthn browser APIs" "PASS"
    else
        print_test_result "Uses correct WebAuthn browser APIs" "FAIL"
    fi
fi

js_reg_file="themes/src/main/resources/theme/usai/login/resources/js/webauthnRegister.js"
if [ -f "$js_reg_file" ]; then
    if grep -q "navigator.credentials.create" "$js_reg_file"; then
        print_test_result "Uses correct WebAuthn registration APIs" "PASS"
    else
        print_test_result "Uses correct WebAuthn registration APIs" "FAIL"
    fi
fi

js_passkey_file="themes/src/main/resources/theme/usai/login/resources/js/passkeysConditionalAuth.js"
if [ -f "$js_passkey_file" ]; then
    if grep -q "PublicKeyCredential.isConditionalMediationAvailable" "$js_passkey_file"; then
        print_test_result "Uses conditional mediation API for passkeys" "PASS"
    else
        print_test_result "Uses conditional mediation API for passkeys" "FAIL"
    fi
fi

echo ""
echo "=================================================="
echo "🔐 WebAuthn Implementation Test Results"
echo "=================================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! WebAuthn implementation is complete.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Deploy the theme to your Keycloak instance"
    echo "2. Configure WebAuthn policies for your realm"
    echo "3. Test with actual security keys/passkeys"
    echo "4. Verify HTTPS is enabled (required for WebAuthn)"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the implementation.${NC}"
    exit 1
fi
