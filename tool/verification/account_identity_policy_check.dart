import '../../lib/services/account_identity_policy.dart';

void main() {
  var checks = 0;
  void check(bool condition, String name) {
    if (!condition) throw StateError(name);
    checks++;
  }

  bool trusted({
    bool anonymous = false,
    bool verified = false,
    String? provider,
    Map<String, dynamic>? claims,
  }) => AccountIdentityPolicy.isTrusted(
    isAnonymous: anonymous,
    emailVerified: verified,
    signInProvider: provider,
    claims: claims,
  );

  check(!trusted(), 'No anonymous/unknown identity accepted');
  check(!trusted(anonymous: true, verified: true), 'Anonymous never trusted');
  check(
    !trusted(provider: 'password'),
    'Legacy password requires email verification',
  );
  check(
    trusted(provider: 'password', verified: true),
    'Existing verified email account retained',
  );
  check(
    trusted(provider: 'google.com'),
    'Google identity does not need password email flow',
  );
  for (final provider in ['kakao', 'naver', 'facebook']) {
    final claims = <String, dynamic>{
      'garden_social_verified': true,
      'garden_social_provider': provider,
    };
    check(
      trusted(provider: 'custom', claims: claims),
      '$provider verified custom token accepted',
    );
    check(
      !trusted(provider: 'password', claims: claims),
      'Claims from incorrect sign-in provider rejected',
    );
    check(
      !trusted(
        provider: 'custom',
        claims: {...claims, 'garden_social_verified': 'true'},
      ),
      'String trust flag rejected',
    );
    check(
      !trusted(anonymous: true, provider: 'custom', claims: claims),
      '$provider never authorizes anonymous accounts',
    );
  }
  check(
    !trusted(
      provider: 'custom',
      claims: {
        'garden_social_verified': true,
        'garden_social_provider': 'other',
      },
    ),
    'Unknown custom provider rejected',
  );
  check(
    !trusted(provider: 'custom', claims: {'garden_social_provider': 'naver'}),
    'Unverified custom provider rejected',
  );
  check(
    AccountIdentityPolicy.providerLabel(
          signInProvider: 'custom',
          claims: {
            'garden_social_verified': true,
            'garden_social_provider': 'kakao',
          },
        ) ==
        '카카오',
    'Trusted provider label',
  );
  check(
    AccountIdentityPolicy.providerLabel(
          signInProvider: 'custom',
          claims: {'garden_social_provider': 'kakao'},
        ) ==
        '계정',
    'Untrusted provider not mislabeled',
  );
  check(
    AccountIdentityPolicy.providerLabel(
          signInProvider: 'custom',
          claims: {
            'garden_social_verified': true,
            'garden_social_provider': 'facebook',
          },
        ) ==
        'Facebook',
    'Facebook provider label',
  );

  const server =
      'https://asia-northeast3-example.cloudfunctions.net/socialAuth';
  final state = List.filled(43, 's').join();
  final providerUrls = {
    'kakao': 'https://kauth.kakao.com/oauth/authorize',
    'naver': 'https://nid.naver.com/oauth2.0/authorize',
    'facebook': 'https://www.facebook.com/v25.0/dialog/oauth',
  };
  String authUrl(String provider, {Map<String, String>? override}) =>
      Uri.parse(providerUrls[provider]!)
          .replace(
            queryParameters: {
              'response_type': 'code',
              'client_id': 'test-client',
              'redirect_uri': server,
              'state': state,
              ...?override,
            },
          )
          .toString();
  bool valid(String url, String provider) =>
      SocialAuthAuthorizationPolicy.validate(
        url,
        provider: provider,
        callbackUrl: server,
      ) !=
      null;
  for (final provider in providerUrls.keys) {
    final url = authUrl(provider);
    check(valid(url, provider), '$provider authorization URL accepted');
    check(
      !valid(authUrl(provider, override: {'response_type': 'token'}), provider),
      '$provider implicit token flow rejected',
    );
    check(
      !valid(
        authUrl(provider, override: {'redirect_uri': 'https://evil.test'}),
        provider,
      ),
      '$provider callback substitution rejected',
    );
    check(
      !valid('$url&state=$state', provider),
      '$provider duplicate OAuth state rejected',
    );
    check(!valid('$url#redirect', provider), '$provider fragments rejected');
  }
  check(
    !valid(authUrl('facebook'), 'naver'),
    'Selected provider cannot switch',
  );
  check(
    !valid(
      authUrl(
        'facebook',
      ).replaceFirst('www.facebook.com', 'www.facebook.com.evil.test'),
      'facebook',
    ),
    'Lookalike Facebook host rejected',
  );
  check(
    !valid(
      authUrl(
        'facebook',
      ).replaceFirst('www.facebook.com', 'evil@www.facebook.com'),
      'facebook',
    ),
    'Authorization user info rejected',
  );
  check(
    !valid(
      authUrl(
        'facebook',
      ).replaceFirst('www.facebook.com', 'www.facebook.com:444'),
      'facebook',
    ),
    'Authorization port rejected',
  );
  check(
    !valid(
      authUrl('facebook').replaceFirst('/dialog/oauth', '/other'),
      'facebook',
    ),
    'Unrelated provider page rejected',
  );
  check(
    !valid(authUrl('facebook', override: {'state': 'short'}), 'facebook'),
    'Malformed OAuth state rejected',
  );
  check(
    SocialAuthAuthorizationPolicy.isValidEndpoint(server),
    'HTTPS server endpoint accepted',
  );
  for (final endpoint in [
    '',
    'http://localhost',
    '$server?token=secret',
    '$server#fragment',
    'https://user@example.com',
  ]) {
    check(
      !SocialAuthAuthorizationPolicy.isValidEndpoint(endpoint),
      'Invalid auth endpoint rejected: $endpoint',
    );
  }
  check(
    SocialAuthAuthorizationPolicy.isOpaqueSession(state),
    'Opaque session accepted',
  );
  check(
    !SocialAuthAuthorizationPolicy.isOpaqueSession('short'),
    'Short session rejected',
  );
  check(
    !SocialAuthAuthorizationPolicy.isOpaqueSession(123),
    'Non-string session rejected',
  );

  const base = '${SocialAuthCallbackPolicy.callbackScheme}://callback';
  String? error(String callback) => SocialAuthCallbackPolicy.errorFor(
    callback,
    expectedSession: 'expected-session',
  );
  check(
    error('$base?session=expected-session') == null,
    'Matching callback accepted',
  );
  check(
    error('$base?session=other-session') == 'invalid-callback',
    'Session injection rejected',
  );
  check(
    error('$base?session=expected-session&session=other') == 'invalid-callback',
    'Duplicate session rejected',
  );
  check(
    error('$base?session=expected-session&error=login-cancelled') ==
        'login-cancelled',
    'Explicit cancel recognized',
  );
  check(
    error('$base?session=expected-session&error=provider-error') ==
        'provider-error',
    'Provider failure retained',
  );
  check(
    error('$base?session=expected-session&error=x&error=y') ==
        'invalid-callback',
    'Duplicate error rejected',
  );
  check(
    error('https://callback?session=expected-session') == 'invalid-callback',
    'Wrong scheme rejected',
  );
  check(
    error(
          '${SocialAuthCallbackPolicy.callbackScheme}://other?session=expected-session',
        ) ==
        'invalid-callback',
    'Wrong host rejected',
  );
  check(
    error('$base/other?session=expected-session') == 'invalid-callback',
    'Wrong path rejected',
  );
  check(
    error('$base?session=expected-session#other') == 'invalid-callback',
    'Fragment rejected',
  );
  check(
    error(
          '${SocialAuthCallbackPolicy.callbackScheme}://attacker@callback?session=expected-session',
        ) ==
        'invalid-callback',
    'User info rejected',
  );
  check(
    error('$base:443?session=expected-session') == 'invalid-callback',
    'Port rejected',
  );
  check(
    error('$base?session=expected-session&customToken=fake') ==
        'invalid-callback',
    'Deep links cannot inject Firebase tokens',
  );
  print('Account identity and OAuth callback checks passed: $checks');
}
