<#macro conditionalUIData>
    <#if enableWebAuthnConditionalUI?has_content>
        <form id="webauth" action="${url.loginAction}" method="post">
            <input type="hidden" id="clientDataJSON" name="clientDataJSON"/>
            <input type="hidden" id="authenticatorData" name="authenticatorData"/>
            <input type="hidden" id="signature" name="signature"/>
            <input type="hidden" id="credentialId" name="credentialId"/>
            <input type="hidden" id="userHandle" name="userHandle"/>
            <input type="hidden" id="error" name="error"/>
        </form>
        <script type="module">
           import { authenticateByWebAuthn } from "${url.resourcesPath}/js/webauthnAuthenticate.js";
           import { initAuthenticate } from "${url.resourcesPath}/js/passkeysConditionalAuth.js";

           const args = {
               isUserIdentified : ${isUserIdentified},
               challenge : '${challenge}',
               userVerification : '${userVerification}',
               rpId : '${rpId}',
               createTimeout : ${createTimeout?c}
           };

           document.addEventListener("DOMContentLoaded", (event) => initAuthenticate({errmsg : "${msg("passkey-unsupported-browser-text")?no_esc}", ...args}));
           const authButton = document.getElementById('authenticateWebAuthnButton');
           if (authButton) {
               authButton.addEventListener("click", (event) => {
                   event.preventDefault();
                   authenticateByWebAuthn({errmsg : "${msg("webauthn-unsupported-browser-text")?no_esc}", ...args});
               });
           }
        </script>
        <div class="webauthn-passkey-option">
            <div class="usa-alert usa-alert--info usa-alert--slim usa-alert--no-icon">
                <div class="usa-alert__body">
                    <p class="usa-alert__text">
                        <strong>Tip:</strong> If you have a passkey registered, you can use it by clicking in the username field above.
                    </p>
                </div>
            </div>
            <a id="authenticateWebAuthnButton" href="#" class="usa-button usa-button--outline usa-button--full-width">
                <svg class="usa-icon" aria-hidden="true" focusable="false" role="img">
                    <use xlink:href="#svg-key"></use>
                </svg>
                ${kcSanitize(msg("webauthn-doAuthenticate"))?no_esc}
            </a>
        </div>
    </#if>
</#macro>
