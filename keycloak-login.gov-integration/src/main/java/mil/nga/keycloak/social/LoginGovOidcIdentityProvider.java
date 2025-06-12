package mil.nga.keycloak.social;

import org.keycloak.broker.oidc.OIDCIdentityProvider;
import org.keycloak.broker.oidc.OIDCIdentityProviderConfig;
import org.keycloak.broker.social.SocialIdentityProvider;
import org.keycloak.crypto.KeyWrapper;
import org.keycloak.jose.jws.JWSInput;
import org.keycloak.keys.loader.OIDCIdentityProviderPublicKeyLoader;
import org.keycloak.models.KeycloakSession;
import mil.nga.keycloak.keys.loader.LoginGovOIDCIdentityProviderPublicKeyLoader;

public class LoginGovOidcIdentityProvider extends OIDCIdentityProvider implements SocialIdentityProvider<OIDCIdentityProviderConfig> {

    public LoginGovOidcIdentityProvider(KeycloakSession session, OIDCIdentityProviderConfig config) {
        super(session, config);
    }

    @Override
    protected KeyWrapper getIdentityProviderKeyWrapper(JWSInput jws) {
        // Use our custom public key loader to handle login.gov's JWKS endpoint
        // which doesn't set the "use" parameter correctly
        OIDCIdentityProviderPublicKeyLoader loader = new LoginGovOIDCIdentityProviderPublicKeyLoader(session, getConfig());
        
        // First try to get the key using our custom loader
        try {
            String kid = jws.getHeader().getKeyId();
            if (kid != null) {
                // Load keys and find the one with matching kid
                var keys = loader.loadKeys();
                for (KeyWrapper key : keys.getKeys()) {
                    if (kid.equals(key.getKid())) {
                        return key;
                    }
                }
            } else {
                // If no kid specified, return the first available signing key
                var keys = loader.loadKeys();
                if (!keys.getKeys().isEmpty()) {
                    return keys.getKeys().get(0);
                }
            }
        } catch (Exception e) {
            logger.warn("Failed to load keys using custom loader, falling back to default", e);
        }
        
        // Fall back to the default implementation if our custom loader fails
        return super.getIdentityProviderKeyWrapper(jws);
    }
}
