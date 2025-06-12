package mil.nga.keycloak.social;

import org.keycloak.broker.oidc.OIDCIdentityProviderConfig;
import org.keycloak.broker.provider.AbstractIdentityProviderFactory;
import org.keycloak.models.IdentityProviderModel;
import org.keycloak.broker.social.SocialIdentityProviderFactory;
import org.keycloak.models.KeycloakSession;

public class LoginGovOidcIdentityProviderFactory extends AbstractIdentityProviderFactory<LoginGovOidcIdentityProvider>
        implements SocialIdentityProviderFactory<LoginGovOidcIdentityProvider> {

    public static final String PROVIDER_ID = "login.gov";

    @Override
    public String getName() {
        return "Login.gov";
    }

    @Override
    public LoginGovOidcIdentityProvider create(KeycloakSession session, IdentityProviderModel model) {
        return new LoginGovOidcIdentityProvider(session, new OIDCIdentityProviderConfig(model));
    }

    @Override
    public OIDCIdentityProviderConfig createConfig() {
        return new OIDCIdentityProviderConfig();
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
