<#macro logoutOtherSessions>
    <div id="kc-form-options" class="${properties.kcFormOptionsClass!}">
        <div class="${properties.kcFormOptionsWrapperClass!}">
            <div class="usa-checkbox">
                <input type="checkbox" id="logout-sessions" name="logout-sessions" value="on" class="usa-checkbox__input">
                <label for="logout-sessions" class="usa-checkbox__label">
                    ${msg("logoutOtherSessions")}
                </label>
            </div>
        </div>
    </div>
</#macro>
