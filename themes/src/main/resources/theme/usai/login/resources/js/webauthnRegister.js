import { base64url } from "rfc4648";

export async function registerByWebAuthn(input) {
    console.log("🔐 WebAuthn Registration Started");
    console.log("🔐 Input parameters:", {
        rpId: input.rpId,
        rpEntityName: input.rpEntityName,
        username: input.username,
        userid: input.userid,
        attestationConveyancePreference: input.attestationConveyancePreference,
        authenticatorAttachment: input.authenticatorAttachment,
        requireResidentKey: input.requireResidentKey,
        userVerificationRequirement: input.userVerificationRequirement,
        createTimeout: input.createTimeout,
        signatureAlgorithms: input.signatureAlgorithms,
        excludeCredentialIds: input.excludeCredentialIds
    });

    // Check if WebAuthn is supported by this browser
    if (!window.PublicKeyCredential) {
        console.error("🔐 WebAuthn not supported by browser");
        returnFailure(input.errmsg);
        return;
    }
    console.log("🔐 WebAuthn is supported");

    console.log("🔐 Building publicKey options");
    const publicKey = {
        challenge: base64url.parse(input.challenge, {loose: true}),
        rp: {id: input.rpId, name: input.rpEntityName},
        user: {
            id: base64url.parse(input.userid, {loose: true}),
            name: input.username,
            displayName: input.username
        },
        pubKeyCredParams: getPubKeyCredParams(input.signatureAlgorithms),
    };

    if (input.attestationConveyancePreference !== 'not specified') {
        publicKey.attestation = input.attestationConveyancePreference;
        console.log(`🔐 Attestation preference: ${input.attestationConveyancePreference}`);
    }

    const authenticatorSelection = {};
    let isAuthenticatorSelectionSpecified = false;

    if (input.authenticatorAttachment !== 'not specified') {
        authenticatorSelection.authenticatorAttachment = input.authenticatorAttachment;
        isAuthenticatorSelectionSpecified = true;
        console.log(`🔐 Authenticator attachment: ${input.authenticatorAttachment}`);
    }

    if (input.requireResidentKey !== 'not specified') {
        if (input.requireResidentKey === 'Yes') {
            authenticatorSelection.requireResidentKey = true;
        } else {
            authenticatorSelection.requireResidentKey = false;
        }
        isAuthenticatorSelectionSpecified = true;
        console.log(`🔐 Require resident key: ${input.requireResidentKey}`);
    }

    if (input.userVerificationRequirement !== 'not specified') {
        authenticatorSelection.userVerification = input.userVerificationRequirement;
        isAuthenticatorSelectionSpecified = true;
        console.log(`🔐 User verification: ${input.userVerificationRequirement}`);
    }

    if (isAuthenticatorSelectionSpecified) {
        publicKey.authenticatorSelection = authenticatorSelection;
        console.log("🔐 Authenticator selection:", authenticatorSelection);
    }

    if (input.createTimeout !== 0) {
        publicKey.timeout = input.createTimeout * 1000;
        console.log(`🔐 Timeout: ${publicKey.timeout}ms`);
    }

    const excludeCredentials = getExcludeCredentials(input.excludeCredentialIds);
    if (excludeCredentials.length > 0) {
        publicKey.excludeCredentials = excludeCredentials;
        console.log(`🔐 Excluding ${excludeCredentials.length} credentials`);
    }

    console.log("🔐 Final publicKey options:", publicKey);

    try {
        console.log("🔐 Calling navigator.credentials.create()");
        const result = await doRegister(publicKey);
        console.log("✅ WebAuthn Registration SUCCESS!");
        returnSuccess(result, input.initLabel, input.initLabelPrompt);
    } catch (error) {
        console.error("❌ WebAuthn Registration FAILED!");
        console.error("🔐 Error:", error);
        returnFailure(error);
    }
}

function doRegister(publicKey) {
    return navigator.credentials.create({publicKey});
}

function getPubKeyCredParams(signatureAlgorithmsList) {
    const pubKeyCredParams = [];
    if (signatureAlgorithmsList.length === 0) {
        pubKeyCredParams.push({type: "public-key", alg: -7});
        return pubKeyCredParams;
    }

    for (const entry of signatureAlgorithmsList) {
        pubKeyCredParams.push({
            type: "public-key",
            alg: entry
        });
    }

    return pubKeyCredParams;
}

function getExcludeCredentials(excludeCredentialIds) {
    const excludeCredentials = [];
    if (excludeCredentialIds === "") {
        return excludeCredentials;
    }

    for (const entry of excludeCredentialIds.split(',')) {
        excludeCredentials.push({
            type: "public-key",
            id: base64url.parse(entry, {loose: true})
        });
    }

    return excludeCredentials;
}

function getTransportsAsString(transportsList) {
    if (!Array.isArray(transportsList)) {
        return "";
    }

    return transportsList.join();
}

function returnSuccess(result, initLabel, initLabelPrompt) {
    console.log("🔐 Processing registration success");
    console.log("🔐 Credential ID:", base64url.stringify(new Uint8Array(result.rawId), {pad: false}));
    console.log("🔐 Response type:", result.response.constructor.name);
    console.log("🔐 Client data JSON length:", result.response.clientDataJSON.byteLength);
    console.log("🔐 Attestation object length:", result.response.attestationObject.byteLength);
    
    document.getElementById("clientDataJSON").value = base64url.stringify(new Uint8Array(result.response.clientDataJSON), {pad: false});
    document.getElementById("attestationObject").value = base64url.stringify(new Uint8Array(result.response.attestationObject), {pad: false});
    document.getElementById("publicKeyCredentialId").value = base64url.stringify(new Uint8Array(result.rawId), {pad: false});

    if (typeof result.response.getTransports === "function") {
        const transports = result.response.getTransports();
        if (transports) {
            console.log("🔐 Available transports:", transports);
            document.getElementById("transports").value = getTransportsAsString(transports);
        } else {
            console.log("🔐 No transports returned");
        }
    } else {
        console.log("🔐 Browser does not support getTransports()");
    }

    console.log(`🔐 Prompting for authenticator label: "${initLabelPrompt}"`);
    let labelResult = window.prompt(initLabelPrompt, initLabel);
    if (labelResult === null) {
        labelResult = initLabel;
        console.log(`🔐 User cancelled prompt, using default label: "${labelResult}"`);
    } else {
        console.log(`🔐 User provided label: "${labelResult}"`);
    }
    document.getElementById("authenticatorLabel").value = labelResult;

    console.log("🔐 Submitting registration form");
    document.getElementById("register").requestSubmit();
}

function returnFailure(err) {
    console.error("🔐 Processing registration failure");
    console.error("🔐 Error:", err);
    console.error("🔐 Error name:", err.name);
    console.error("🔐 Error message:", err.message);
    
    document.getElementById("error").value = err;
    console.log("🔐 Submitting error form");
    document.getElementById("register").requestSubmit();
}
