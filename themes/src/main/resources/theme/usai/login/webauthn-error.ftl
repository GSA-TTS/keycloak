<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "title">
        ${msg("webauthn-error-title")}
    <#elseif section = "header">
        ${kcSanitize(msg("webauthn-error-title"))?no_esc}
    <#elseif section = "form">
        <div class="usa-card__body">
            <div class="usa-alert usa-alert--error">
                <div class="usa-alert__body">
                    <h3 class="usa-alert__heading">${msg("webauthn-error-title")}</h3>
                    <p class="usa-alert__text">
                        <#if isUserIdentified?? && isUserIdentified>
                            ${kcSanitize(msg("webauthn-error-registration"))?no_esc}
                        <#else>
                            ${kcSanitize(msg("webauthn-error-api-get"))?no_esc}
                        </#if>
                    </p>
                </div>
            </div>

            <div class="webauthn-error-details">
                <details class="usa-details">
                    <summary class="usa-details__summary">Technical Details</summary>
                    <div class="usa-details__content">
                        <#if webAuthnErrorMessage??>
                            <p><strong>Error:</strong> ${kcSanitize(webAuthnErrorMessage)?no_esc}</p>
                        </#if>
                        <p><strong>Possible causes:</strong></p>
                        <ul>
                            <li>Security key not supported by this browser</li>
                            <li>Security key not properly inserted or connected</li>
                            <li>User cancelled the operation</li>
                            <li>Network connectivity issues</li>
                        </ul>
                    </div>
                </details>
            </div>

            <div id="kc-form-buttons" class="${properties.kcFormButtonsClass!}">
                <#if isUserIdentified?? && isUserIdentified>
                    <form action="${url.loginAction}" class="${properties.kcFormClass!}" method="post">
                        <button type="submit" class="usa-button usa-button--primary" name="try-again" value="true">
                            ${msg("doTryAgain")}
                        </button>
                    </form>
                <#else>
                    <a href="${url.loginUrl}" class="usa-button usa-button--primary">
                        ${msg("backToLogin")}
                    </a>
                </#if>
                
                <#if url.loginUrl??>
                    <a href="${url.loginUrl}" class="usa-button usa-button--outline">
                        ${msg("backToLogin")}
                    </a>
                </#if>
            </div>
            
            <div class="login-footer-text">
                <p>USAi is available only from an approved government network within a participating agency.</p>
            </div>
        </div>
    </#if>
</@layout.registrationLayout>
