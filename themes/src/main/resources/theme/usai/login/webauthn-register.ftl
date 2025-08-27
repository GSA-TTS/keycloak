<#import "template.ftl" as layout>
<#import "password-commons.ftl" as passwordCommons>

<@layout.registrationLayout; section>
    <#if section = "title">
        ${msg("webauthn-registration-title")}
    <#elseif section = "header">
        <span class="${properties.kcWebAuthnKeyIcon!}"></span>
        ${kcSanitize(msg("webauthn-registration-title"))?no_esc}
    <#elseif section = "form">
        <div class="usa-card__body">
            <p class="login-description">Register your security key to enable passwordless sign-in to USAi.</p>
            
            <div class="webauthn-registration-info">
                <div class="usa-alert usa-alert--info usa-alert--slim">
                    <div class="usa-alert__body">
                        <p class="usa-alert__text">
                            <strong>Security Key Registration:</strong> You can register a security key after authenticating through your authorized identity provider (such as Login.gov). This will enable faster, passwordless access for future logins.
                        </p>
                        <p class="usa-alert__text">
                            You'll need a compatible security key (like a YubiKey) or use your device's built-in authenticator (Touch ID, Face ID, Windows Hello, etc.).
                        </p>
                    </div>
                </div>
            </div>

            <form id="register" class="${properties.kcFormClass!}" action="${url.loginAction}" method="post">
                <div class="${properties.kcFormGroupClass!}">
                    <input type="hidden" id="clientDataJSON" name="clientDataJSON"/>
                    <input type="hidden" id="attestationObject" name="attestationObject"/>
                    <input type="hidden" id="publicKeyCredentialId" name="publicKeyCredentialId"/>
                    <input type="hidden" id="authenticatorLabel" name="authenticatorLabel"/>
                    <input type="hidden" id="transports" name="transports"/>
                    <input type="hidden" id="error" name="error"/>
                    <@passwordCommons.logoutOtherSessions/>
                </div>
            </form>

            <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                <input type="submit"
                       class="usa-button usa-button--primary"
                       id="registerWebAuthn" value="${msg("doRegisterSecurityKey")}"/>
            </div>

            <#if !isSetRetry?has_content && isAppInitiatedAction?has_content>
                <form action="${url.loginAction}" class="${properties.kcFormClass!}" id="kc-webauthn-settings-form"
                      method="post">
                    <button type="submit"
                            class="usa-button usa-button--outline"
                            id="cancelWebAuthnAIA" name="cancel-aia" value="true">${msg("doCancel")}
                    </button>
                </form>
            </#if>
            
            <div class="login-footer-text">
                <p>USAi is available only from an approved government network within a participating agency.</p>
            </div>
        </div>

        <script type="module">
            import { registerByWebAuthn } from "${url.resourcesPath}/js/webauthnRegister.js";
            const registerButton = document.getElementById('registerWebAuthn');
            registerButton.addEventListener("click", function() {
                const input = {
                    challenge : '${challenge}',
                    userid : '${userid}',
                    username : '${username}',
                    signatureAlgorithms : [<#list signatureAlgorithms as sigAlg>${sigAlg?c},</#list>],
                    rpEntityName : '${rpEntityName}',
                    rpId : '${rpId}',
                    attestationConveyancePreference : '${attestationConveyancePreference}',
                    authenticatorAttachment : '${authenticatorAttachment}',
                    requireResidentKey : '${requireResidentKey}',
                    userVerificationRequirement : '${userVerificationRequirement}',
                    createTimeout : ${createTimeout?c},
                    excludeCredentialIds : '${excludeCredentialIds}',
                    initLabel : "${msg("webauthn-registration-init-label")?no_esc}",
                    initLabelPrompt : "${msg("webauthn-registration-init-label-prompt")?no_esc}",
                    errmsg : "${msg("webauthn-unsupported-browser-text")?no_esc}"
                };
                registerByWebAuthn(input);
            });
        </script>

    </#if>
</@layout.registrationLayout>
