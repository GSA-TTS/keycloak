import { base64url } from "rfc4648";
import { returnSuccess, signal } from "./webauthnAuthenticate.js";

export function initAuthenticate(input, availableCallback = (available) => {}) {
    console.log("🔐 Passkeys Conditional Auth: Initializing");
    console.log("🔐 Input parameters:", {
        isUserIdentified: input.isUserIdentified,
        rpId: input.rpId,
        userVerification: input.userVerification,
        createTimeout: input.createTimeout
    });
    
    // Check if WebAuthn is supported by this browser
    if (!window.PublicKeyCredential) {
        console.log("🔐 WebAuthn not supported - conditional auth unavailable");
        // Fail silently as WebAuthn Conditional UI is not required
        return;
    }
    
    if (input.isUserIdentified || typeof PublicKeyCredential.isConditionalMediationAvailable === "undefined") {
        console.log("🔐 Conditional mediation not available:", {
            isUserIdentified: input.isUserIdentified,
            hasConditionalMediation: typeof PublicKeyCredential.isConditionalMediationAvailable !== "undefined"
        });
        availableCallback(false);
    } else {
        console.log("🔐 Checking conditional mediation availability");
        tryAutoFillUI(input, availableCallback);
    }
}

function doAuthenticate(input) {
    console.log("🔐 Conditional Auth: Starting doAuthenticate");
    
    // Check if WebAuthn is supported by this browser
    if (!window.PublicKeyCredential) {
        console.log("🔐 WebAuthn not supported - failing silently");
        // Fail silently as WebAuthn Conditional UI is not required
        return;
    }

    const publicKey = {
        rpId : input.rpId,
        challenge: base64url.parse(input.challenge, { loose: true })
    };

    publicKey.allowCredentials = !input.isUserIdentified ? [] : getAllowCredentials();
    console.log(`🔐 Allow credentials count: ${publicKey.allowCredentials.length}`);

    if (input.createTimeout !== 0) {
        publicKey.timeout = input.createTimeout * 1000;
        console.log(`🔐 Timeout: ${publicKey.timeout}ms`);
    }

    if (input.userVerification !== 'not specified') {
        publicKey.userVerification = input.userVerification;
        console.log(`🔐 User verification: ${input.userVerification}`);
    }

    console.log("🔐 PublicKey options for conditional auth:", publicKey);
    console.log("🔐 Additional options:", input.additionalOptions);
    console.log("🔐 Calling navigator.credentials.get() with conditional mediation");

    return navigator.credentials.get({
        publicKey: publicKey,
        signal: signal(),
        ...input.additionalOptions
    });
}

async function tryAutoFillUI(input, availableCallback = (available) => {}) {
    console.log("🔐 Checking if conditional mediation is available");
    const isConditionalMediationAvailable = await PublicKeyCredential.isConditionalMediationAvailable();
    console.log(`🔐 Conditional mediation available: ${isConditionalMediationAvailable}`);
    
    if (isConditionalMediationAvailable) {
        console.log("🔐 Conditional mediation is available - setting up autofill UI");
        availableCallback(true);
        input.additionalOptions = { mediation: 'conditional'};
        try {
            console.log("🔐 Starting conditional authentication");
            const result = await doAuthenticate(input);
            console.log("✅ Conditional authentication SUCCESS!");
            returnSuccess(result);
        } catch (error) {
            console.log("🔐 Conditional authentication failed (silent):", error);
            // Fail silently as WebAuthn Conditional UI is not required
        }
    } else {
        console.log("🔐 Conditional mediation not available");
        availableCallback(false);
    }
}

function getAllowCredentials() {
    console.log("🔐 Getting allow credentials for conditional auth");
    const allowCredentials = [];
    const authnUse = document.forms['authn_select'].authn_use_chk;
    if (authnUse !== undefined) {
        if (authnUse.length === undefined) {
            console.log("🔐 Found single credential for conditional auth");
            allowCredentials.push({
                id: base64url.parse(authnUse.value, {loose: true}),
                type: 'public-key',
            });
        } else {
            console.log(`🔐 Found ${authnUse.length} credentials for conditional auth`);
            authnUse.forEach((entry) =>
                allowCredentials.push({
                    id: base64url.parse(entry.value, {loose: true}),
                    type: 'public-key',
                }));
        }
    } else {
        console.log("🔐 No credentials found in form for conditional auth");
    }
    console.log(`🔐 Total allowCredentials for conditional auth: ${allowCredentials.length}`);
    return allowCredentials;
}
