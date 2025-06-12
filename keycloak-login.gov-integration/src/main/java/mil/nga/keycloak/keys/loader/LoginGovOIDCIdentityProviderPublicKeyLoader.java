package mil.nga.keycloak.keys.loader;

import org.jboss.logging.Logger;
import org.keycloak.broker.oidc.OIDCIdentityProviderConfig;
import org.keycloak.crypto.KeyWrapper;
import org.keycloak.crypto.PublicKeysWrapper;
import org.keycloak.jose.jwk.JSONWebKeySet;
import org.keycloak.jose.jwk.JWK;
import org.keycloak.keys.loader.OIDCIdentityProviderPublicKeyLoader;
import org.keycloak.models.KeycloakSession;
import org.keycloak.protocol.oidc.utils.JWKSHttpUtils;
import org.keycloak.util.JWKSUtils;

import java.util.ArrayList;
import java.util.List;

/**
 * This class just exists to allow instantiation of the LoginGovIdentityProviderPublicKeyLoader.
 * The purpose is to fix a bug caused by the login.gov jwks certs endpoint where they do
 * not set the JWKS Spec https://tools.ietf.org/html/draft-ietf-jose-json-web-key-41#section-4.2
 * 4.2 OPTIONAL "use"="sig"
 *
 * This causes the login.gov jwks endpoint to fail subsequent checks and token fails with a
 * validation exception.
 *
 * Modified from Original:  org.keycloak.keys.loader.OIDCIdentityProviderPublicKeyLoader
 */
public class LoginGovOIDCIdentityProviderPublicKeyLoader extends OIDCIdentityProviderPublicKeyLoader {
    private static final Logger logger = Logger.getLogger(OIDCIdentityProviderPublicKeyLoader.class);

    private final KeycloakSession session;
    private final OIDCIdentityProviderConfig config;

    public LoginGovOIDCIdentityProviderPublicKeyLoader(KeycloakSession session, OIDCIdentityProviderConfig config) {
        super(session, config);
        this.config = config;
        this.session = session;
    }

    @Override
    public PublicKeysWrapper loadKeys() throws Exception {
        if (config.isUseJwksUrl()) {
            String jwksUrl = config.getJwksUrl();
            JSONWebKeySet jwks = JWKSHttpUtils.sendJwksRequest(session, jwksUrl);

            // Patch to function with login.gov -- force a default "use" = "sig" for null "use"
            // This ensures that keys without an explicit 'use' parameter are treated as signing keys,
            // which is necessary for login.gov's JWKS endpoint.
            jwks.getKeys().stream()
                .filter(jwk -> jwk.getPublicKeyUse() == null)
                .forEach(jwk -> {
                    logger.debugf("Patching JWK with kid '%s': 'use' parameter is null, forcing to 'sig'", jwk.getKeyId());
                    jwk.setPublicKeyUse(JWK.Use.SIG.asString());
                });

            // Assuming JWKSUtils.getKeyWrappersForUse now returns PublicKeysWrapper
            return JWKSUtils.getKeyWrappersForUse(jwks, JWK.Use.SIG);
        } else {
            // Return an empty list of KeyWrapper objects
            return new PublicKeysWrapper(new ArrayList<>());
        }
    }
}
