<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('username','password') displayInfo=realm.password && realm.registrationAllowed && !registrationDisabled??; section>
    <#if section = "header">
        Sign in
    <#elseif section = "form">
        <div id="kc-form">
          <div id="kc-form-wrapper">
            <div class="usa-card__body">
                <p class="login-description">Sign in with your agency credentials to access USAi.</p>
                
                <#if realm.identityProviders??>
                    <div id="kc-social-providers" class="${properties.kcFormSocialAccountSectionClass!}">
                        <hr/>
                        <h4>${msg("identity-provider-login-label")}</h4>
                        <ul class="${properties.kcFormSocialAccountListClass!} <#if social.providers?size gt 3>${properties.kcFormSocialAccountListGridClass!}</#if>">
                            <#list realm.identityProviders as p>
                                <#if p.enabled>
                                    <li>
                                        <a id="social-${p.alias}" class="${properties.kcFormSocialAccountListButtonClass!} <#if social.providers?size gt 3>${properties.kcFormSocialAccountGridItem!}</#if>"
                                                type="button" href="${p.loginUrl}">
                                            <#if p.iconClasses?has_content>
                                                <i class="${p.iconClasses!}" aria-hidden="true"></i>
                                                <span class="${properties.kcFormSocialAccountNameClass!} kc-social-icon-text">${p.displayName!}</span>
                                            <#else>
                                                <span class="${properties.kcFormSocialAccountNameClass!}">${p.displayName!}</span>
                                            </#if>
                                        </a>
                                    </li>
                                </#if>
                            </#list>
                        </ul>
                    </div>
                </#if>

                <#if realm.password && social.providers??>
                    <div id="kc-username-password-form" class="${properties.kcFormPasswordSection!}">
                        <hr/>
                        <h4>${msg("username-password-login-label")}</h4>
                    </div>
                </#if>

                <#if realm.password>
                    <form id="kc-form-login" onsubmit="login.disabled = true; return true;" action="${url.loginAction}" method="post">
                        <div class="${properties.kcFormGroupClass!}">
                            <label for="username" class="${properties.kcLabelClass!}">Email address</label>
                            <input tabindex="1" id="username" class="${properties.kcInputClass!}" name="username"
                                   value="${(login.username!'')}" type="text" autofocus autocomplete="username"
                                   aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                                   placeholder="Email"
                                   dir="ltr"
                            />

                            <#if messagesPerField.existsError('username','password')>
                                <span id="input-error-username-password" class="${properties.kcInputErrorMessageClass!}" aria-live="polite">
                                    ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                                </span>
                            </#if>
                        </div>

                        <div class="${properties.kcFormGroupClass!}">
                            <label for="password" class="${properties.kcLabelClass!}">Password</label>
                            <input tabindex="2" id="password" class="${properties.kcInputClass!}" name="password"
                                   type="password" autocomplete="current-password"
                                   aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                                   placeholder="Password"
                                   dir="ltr"
                            />
                        </div>

                        <div id="kc-form-options">
                            <#if realm.rememberMe && !usernameHidden??>
                                <div class="checkbox">
                                    <label>
                                        <#if login.rememberMe??>
                                            <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox" checked> ${msg("rememberMe")}
                                        <#else>
                                            <input tabindex="3" id="rememberMe" name="rememberMe" type="checkbox"> ${msg("rememberMe")}
                                        </#if>
                                    </label>
                                </div>
                            </#if>
                        </div>

                        <div id="kc-form-buttons" class="${properties.kcFormGroupClass!}">
                            <input type="hidden" id="id-hidden-input" name="credentialId" <#if auth.selectedCredential?has_content>value="${auth.selectedCredential}"</#if>/>
                            <input tabindex="4" class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}" name="login" id="kc-login" type="submit" value="${msg("doLogIn")}"/>
                        </div>
                    </form>
                </#if>
                
                <div class="login-footer-text">
                    <p>USAi is available only from an approved government network within a participating agency.</p>
                </div>
            </div>
          </div>
        </div>
    </#if>
</@layout.registrationLayout>
