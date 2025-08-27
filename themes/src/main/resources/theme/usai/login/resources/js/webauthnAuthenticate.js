import { base64url } from "rfc4648";

// singleton
let abortController = undefined;

export function signal() {
    if (abortController) {
        // abort the previous call
        console.log("🔐 WebAuthn: Aborting previous authentication call");
        const abortError = new Error("Cancelling pending WebAuthn call");
        abortError.name = "AbortError";
        abortController.abort(abortError);
    }

    abortController = new AbortController();
    console.log("🔐 WebAuthn: Created new abort controller");
    return abortController.signal;
}

export async function authenticateByWebAuthn(input) {
    console.log("🔐 WebAuthn Authentication Started");
    console.log("🔐 Input parameters:", {
        isUserIdentified: input.isUserIdentified,
        rpId: input.rpId,
        userVerification: input.userVerification,
        createTimeout: input.createTimeout
    });
    
    if (!input.isUserIdentified) {
        console.log("🔐 User not identified - using empty allowCredentials");
        try {
            const result = await doAuthenticate([], input.challenge, input.userVerification, input.rpId, input.createTimeout, input.errmsg);
            returnSuccess(result);
        } catch (error) {
            console.error("🔐 Authentication failed:", error);
            returnFailure(error);
        }
        return;
    }
    console.log("🔐 User identified - checking allow credentials");
    checkAllowCredentials(input.challenge, input.userVerification, input.rpId, input.createTimeout, input.errmsg);
}

async function checkAllowCredentials(challenge, userVerification, rpId, createTimeout, errmsg) {
    console.log("🔐 Checking allow credentials");
    const allowCredentials = [];
    const authnUse = document.forms['authn_select'].authn_use_chk;
    if (authnUse !== undefined) {
        if (authnUse.length === undefined) {
            console.log("🔐 Found single credential");
            allowCredentials.push({
                id: base64url.parse(authnUse.value, {loose: true}),
                type: 'public-key',
            });
        } else {
            console.log(`🔐 Found ${authnUse.length} credentials`);
            authnUse.forEach((entry) =>
                allowCredentials.push({
                    id: base64url.parse(entry.value, {loose: true}),
                    type: 'public-key',
                }));
        }
    }
    console.log(`🔐 Total allowCredentials: ${allowCredentials.length}`);
    try {
        const result = await doAuthenticate(allowCredentials, challenge, userVerification, rpId, createTimeout, errmsg);
        returnSuccess(result);
    } catch (error) {
        console.error("🔐 checkAllowCredentials failed:", error);
        returnFailure(error);
    }
}

function doAuthenticate(allowCredentials, challenge, userVerification, rpId, createTimeout, errmsg) {
    console.log("🔐 Starting doAuthenticate");
    
    // Check if WebAuthn is supported by this browser
    if (!window.PublicKeyCredential) {
        console.error("🔐 WebAuthn not supported by browser");
        returnFailure(errmsg);
        return;
    }

    const publicKey = {
        rpId : rpId,
        challenge: base64url.parse(challenge, { loose: true })
    };

    if (createTimeout !== 0) {
        publicKey.timeout = createTimeout * 1000;
        console.log(`🔐 Set timeout: ${publicKey.timeout}ms`);
    }

    if (allowCredentials.length) {
        publicKey.allowCredentials = allowCredentials;
        console.log(`🔐 Using ${allowCredentials.length} allowCredentials`);
    } else {
        console.log("🔐 No allowCredentials specified - discoverable credentials");
    }

    if (userVerification !== 'not specified') {
        publicKey.userVerification = userVerification;
        console.log(`🔐 User verification: ${userVerification}`);
    }

    console.log("🔐 PublicKey options:", publicKey);
    console.log("🔐 Calling navigator.credentials.get()");

    return navigator.credentials.get({
        publicKey: publicKey,
        signal: signal()
    });
}

export function returnSuccess(result) {
    console.log("✅ WebAuthn Authentication SUCCESS!");
    console.log("🔐 Credential ID:", result.id);
    console.log("🔐 Response type:", result.response.constructor.name);
    console.log("🔐 Client data JSON length:", result.response.clientDataJSON.byteLength);
    console.log("🔐 Authenticator data length:", result.response.authenticatorData.byteLength);
    console.log("🔐 Signature length:", result.response.signature.byteLength);
    
    if (result.response.userHandle) {
        console.log("🔐 User handle present:", base64url.stringify(new Uint8Array(result.response.userHandle), { pad: false }));
    } else {
        console.log("🔐 No user handle in response");
    }
    
    document.getElementById("clientDataJSON").value = base64url.stringify(new Uint8Array(result.response.clientDataJSON), { pad: false });
    document.getElementById("authenticatorData").value = base64url.stringify(new Uint8Array(result.response.authenticatorData), { pad: false });
    document.getElementById("signature").value = base64url.stringify(new Uint8Array(result.response.signature), { pad: false });
    document.getElementById("credentialId").value = result.id;
    if (result.response.userHandle) {
        document.getElementById("userHandle").value = base64url.stringify(new Uint8Array(result.response.userHandle), { pad: false });
    }
    
    console.log("🔐 Submitting authentication form");
    document.getElementById("webauth").requestSubmit();
}

export function returnFailure(err) {
    console.error("❌ WebAuthn Authentication FAILED!");
    console.error("🔐 Error:", err);
    console.error("🔐 Error name:", err.name);
    console.error("🔐 Error message:", err.message);
    
    document.getElementById("error").value = err;
    console.log("🔐 Submitting error form");
    document.getElementById("webauth").requestSubmit();
}
