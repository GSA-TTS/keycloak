<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('password'); section>
    <#if section = "header">
        Sign in
    <#elseif section = "form">
        <div id="kc-form">
            <div id="kc-form-wrapper">
                <div class="usa-card__body">
                    <p class="login-description">Enter your password to access USAi.</p>
                    
                    <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}"
                          method="post">
                        <div class="${properties.kcFormGroupClass!}">
                            <label for="password" class="usa-label">${msg("password")}</label>
                            <div class="${properties.kcInputGroup!}" dir="ltr">
                                <input tabindex="1" id="password" class="usa-input" name="password"
                                       type="password" autocomplete="current-password" autofocus
                                       aria-invalid="<#if messagesPerField.existsError('password')>true</#if>"
                                />
                            </div>
                            <#if messagesPerField.existsError('password')>
                                <span id="input-error-password" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.get('password'))?no_esc}
                                </span>
                            </#if>
                        </div>

                        <div class="${properties.kcFormGroupClass!} ${properties.kcFormSettingClass!}">
                            <div id="kc-form-options">
                                <div class="${properties.kcFormOptionsWrapperClass!}">
                                    <#if realm.resetPasswordAllowed>
                                        <span><a tabindex="3"
                                                 href="${url.loginResetCredentialsUrl}">${msg("doForgotPassword")}</a></span>
                                    </#if>
                                </div>
                            </div>
                        </div>

                        <div id="kc-form-buttons" class="${properties.kcFormGroupClass!}">
                            <input tabindex="2" class="usa-button usa-button--primary" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                        </div>
                    </form>
                    
                    <div class="login-footer-text">
                        <p>USAi is available only from an approved government network within a participating agency.</p>
                    </div>
                </div>
            </div>
        </div>
    </#if>

</@layout.registrationLayout>
