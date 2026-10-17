/// Trust decisions for an authenticated Firebase identity, shared by account
/// screens and purchases. Custom claims are trusted only from a Firebase ID
/// token, never from preferences, an OAuth callback, or a user-entered email.
class AccountIdentityPolicy {
  static const socialProviders = {'kakao', 'naver', 'facebook'};

  static bool isTrusted({
    required bool isAnonymous,
    required bool emailVerified,
    required String? signInProvider,
    Map<String, dynamic>? claims,
  }) {
    if (isAnonymous) return false;
    if (emailVerified || signInProvider == 'google.com') return true;
    return signInProvider == 'custom' &&
        claims?['garden_social_verified'] == true &&
        socialProviders.contains(claims?['garden_social_provider']);
  }

  static String providerLabel({
    required String? signInProvider,
    Map<String, dynamic>? claims,
  }) {
    if (signInProvider == 'google.com') return 'Google';
    if (signInProvider == 'password') return '이메일';
    if (signInProvider == 'custom' &&
        claims?['garden_social_verified'] == true) {
      if (claims?['garden_social_provider'] == 'kakao') return '카카오';
      if (claims?['garden_social_provider'] == 'naver') return '네이버';
      if (claims?['garden_social_provider'] == 'facebook') return 'Facebook';
    }
    return '계정';
  }
}

/// A returned authorization URL must stay on the selected provider and return
/// through this app's configured HTTPS server. Browser callbacks contain only
/// a proof-bound session ID, never provider tokens or a user-selected account.
class SocialAuthAuthorizationPolicy {
  static const _hosts = {
    'kakao': 'kauth.kakao.com',
    'naver': 'nid.naver.com',
    'facebook': 'www.facebook.com',
  };

  static bool isOpaqueSession(Object? value) =>
      value is String && RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(value);

  static bool isValidEndpoint(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.fragment.isEmpty &&
        uri.query.isEmpty;
  }

  static Uri? validate(
    Object? authorizationUrl, {
    required String provider,
    required String callbackUrl,
  }) {
    if (authorizationUrl is! String || !isValidEndpoint(callbackUrl)) {
      return null;
    }
    final uri = Uri.tryParse(authorizationUrl);
    if (uri == null ||
        !_hosts.containsKey(provider) ||
        uri.scheme != 'https' ||
        uri.host != _hosts[provider] ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.fragment.isNotEmpty) {
      return null;
    }
    final validPath = switch (provider) {
      'kakao' => uri.path == '/oauth/authorize',
      'naver' => uri.path == '/oauth2.0/authorize',
      'facebook' => RegExp(r'^/v\d+\.\d+/dialog/oauth$').hasMatch(uri.path),
      _ => false,
    };
    if (!validPath ||
        uri.queryParametersAll['response_type']?.length != 1 ||
        uri.queryParameters['response_type'] != 'code' ||
        uri.queryParametersAll['client_id']?.length != 1 ||
        (uri.queryParameters['client_id'] ?? '').isEmpty ||
        uri.queryParametersAll['redirect_uri']?.length != 1 ||
        uri.queryParameters['redirect_uri'] != callbackUrl ||
        uri.queryParametersAll['state']?.length != 1 ||
        !isOpaqueSession(uri.queryParameters['state'])) {
      return null;
    }
    return uri;
  }
}

/// Reject unrelated/deep-link-injected callbacks before exchanging any token.
class SocialAuthCallbackPolicy {
  static const callbackScheme = 'com.mysticcat.journal.auth';

  static String? errorFor(String callback, {required String expectedSession}) {
    final uri = Uri.tryParse(callback);
    if (uri == null ||
        uri.scheme != callbackScheme ||
        uri.host != 'callback' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.fragment.isNotEmpty ||
        expectedSession.isEmpty ||
        uri.queryParameters.keys.any(
          (key) => key != 'session' && key != 'error',
        ) ||
        uri.queryParametersAll['session']?.length != 1 ||
        uri.queryParameters['session'] != expectedSession ||
        (uri.queryParametersAll['error']?.length ?? 0) > 1) {
      return 'invalid-callback';
    }
    return uri.queryParameters['error'];
  }
}
