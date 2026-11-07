import '../l10n/app_language.dart';
import 'garden_push_service.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'account_identity_policy.dart';
import 'auto_backup_service.dart';

class SocialAuthException implements Exception {
  const SocialAuthException(this.code);
  final String code;

  String get message => switch (code) {
    'firebase-not-ready' => tr(
      "앱의 계정 연결을 시작하지 못했어요. 앱을 다시 실행해 주세요. 계속되면 오류 코드 AUTH-01을 알려 주세요.",
    ),
    'server-url-missing' => tr(
      "이 앱에 로그인 서버 주소가 설정되지 않았어요. 수정된 앱으로 업데이트해 주세요. (AUTH-02)",
    ),
    'provider-disabled' => tr(
      "선택한 로그인 서비스의 서버 설정이 아직 완료되지 않았어요. 오류 코드 AUTH-03을 알려 주세요.",
    ),
    'not-configured' ||
    'client-configuration' => tr("이 로그인 방식은 아직 연결 준비 중이에요. 다른 방법을 선택해 주세요."),
    'unsupported-platform' => tr("간편로그인은 현재 안드로이드 앱에서 이용할 수 있어요."),
    'already-signed-in' => tr("현재 계정을 먼저 로그아웃한 뒤 다른 계정으로 로그인해 주세요."),
    'account-changed' => tr("로그인 계정이 바뀌었어요. 현재 계정을 확인해 주세요."),
    'session-expired' || 'session-used' => tr("로그인 시간이 지났어요. 다시 시작해 주세요."),
    'invalid-callback' ||
    'invalid-proof' => tr("로그인 확인에 실패했어요. 앱에서 다시 시작해 주세요."),
    'app-check-required' => tr(
      "설치된 앱의 인증을 확인하지 못해 로그인을 계속할 수 없어요. 오류 코드 AUTH-04를 알려 주세요.",
    ),
    'app-check-timeout' => tr(
      "앱 인증 확인이 지연되고 있어요. 연결을 확인하고 다시 시도해 주세요. (AUTH-05)",
    ),
    'auth-server-unreachable' => tr(
      "로그인 서버에 연결하지 못했어요. 인터넷 연결을 확인하고 다시 시도해 주세요. (AUTH-06)",
    ),
    'auth-server-not-found' => tr("로그인 서버를 찾지 못했어요. 오류 코드 AUTH-07을 알려 주세요."),
    'auth-server-rejected' => tr(
      "로그인 서버가 앱의 요청을 받아들이지 못했어요. 오류 코드 AUTH-08을 알려 주세요.",
    ),
    'auth-server-response-invalid' => tr(
      "로그인 서버의 응답을 확인하지 못했어요. 오류 코드 AUTH-09를 알려 주세요.",
    ),
    'auth-server-timeout' => tr(
      "로그인 서버의 응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요. (AUTH-10)",
    ),
    'provider-error' => tr(
      "선택한 서비스에서 로그인 인증을 완료하지 못했어요. 다시 시도해 주세요. (AUTH-11)",
    ),
    'browser-open-failed' => tr(
      "로그인 창을 열거나 앱으로 돌아오는 중 오류가 발생했어요. 오류 코드 AUTH-12를 알려 주세요.",
    ),
    'identity-not-verified' => tr("계정 인증을 확인하지 못했어요. 로그아웃 후 다시 로그인해 주세요."),
    'provider-credential-invalid' => tr(
      "선택한 로그인 계정의 인증이 만료되었어요. 간편로그인을 다시 시작해 주세요.",
    ),
    'account-deleting' ||
    'account-busy' => tr("계정 처리가 진행 중이에요. 잠시 후 로그인을 다시 시작해 주세요."),
    'account-disabled' => tr("이용이 중지된 계정이에요. 문의해 주세요."),
    'rate-limit' => tr("요청이 많아요. 잠시 후 로그인을 다시 시작해 주세요."),
    'login-restart-required' => tr("로그인을 처음부터 다시 시작해 주세요."),
    'account-deleted' => tr("삭제된 계정이에요. 계정 복구가 필요하면 문의해 주세요."),
    'login-in-progress' => tr("로그인이 진행 중이에요."),
    _ => tr("로그인을 완료하지 못했어요. 연결을 확인하고 다시 시도해 주세요."),
  };

  @override
  String toString() => message;
}

/// Firebase is the sole signed-in identity. Kakao/Naver/Facebook browser sessions are
/// exchanged through our App-Check-protected server and proof-bound session.
/// Provider secrets and access tokens are never embedded in the app.
class SocialAuthService {
  static const endpoint = String.fromEnvironment('SOCIAL_AUTH_URL');
  static const _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static Future<void>? _googleInitialization;
  static bool _authInProgress = false;

  static bool get firebaseReady => Firebase.apps.isNotEmpty;
  static bool get supportsQuickLogin =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get browserConfigured =>
      SocialAuthAuthorizationPolicy.isValidEndpoint(endpoint);

  static User? get currentUser =>
      firebaseReady ? FirebaseAuth.instance.currentUser : null;
  static bool get signedIn => currentUser != null;

  static Future<bool> isAccountReady({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null || user.isAnonymous) return false;
    final token = await user.getIdTokenResult(forceRefresh);
    if (currentUser?.uid != user.uid) return false;
    return AccountIdentityPolicy.isTrusted(
      isAnonymous: user.isAnonymous,
      emailVerified: user.emailVerified,
      signInProvider: token.signInProvider,
      claims: token.claims,
    );
  }

  static Future<String> providerLabel() async {
    final user = currentUser;
    if (user == null) return tr("로그인 전");
    final token = await user.getIdTokenResult();
    if (currentUser?.uid != user.uid) return tr("계정");
    return AccountIdentityPolicy.providerLabel(
      signInProvider: token.signInProvider,
      claims: token.claims,
    );
  }

  static Future<void> _initializeGoogle() async {
    final existing = _googleInitialization;
    if (existing != null) {
      await existing;
      return;
    }
    final initialization = GoogleSignIn.instance.initialize(
      serverClientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
    );
    _googleInitialization = initialization;
    try {
      await initialization;
    } catch (_) {
      _googleInitialization = null;
      rethrow;
    }
  }

  static Future<OAuthCredential> _googleCredential() async {
    await _initializeGoogle();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const SocialAuthException('unsupported-platform');
    }
    final google = await GoogleSignIn.instance.authenticate();
    final idToken = google.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const SocialAuthException('client-configuration');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// False means the user canceled, not a failed purchase or an auth error.
  static Future<bool> signInWithGoogle() => _authenticate(() async {
    final credential = await _googleCredential();
    if (currentUser != null) throw const SocialAuthException('account-changed');
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    await _verifySignedInUser(result.user, expectedProvider: 'google.com');
  });

  /// An explicit link keeps the existing Firebase UID and purchase ownership.
  /// It is never invoked as an automatic fallback from a login error.
  static Future<bool> linkGoogleToCurrentAccount() async {
    final user = currentUser;
    if (user == null) throw const SocialAuthException('account-changed');
    return _authenticate(() async {
      final credential = await _googleCredential();
      if (currentUser?.uid != user.uid) {
        throw const SocialAuthException('account-changed');
      }
      await user.linkWithCredential(credential);
      await user.reload();
      final refreshed = currentUser;
      if (refreshed == null || refreshed.uid != user.uid) {
        throw const SocialAuthException('account-changed');
      }
      // Linking alone may leave the token's sign-in provider as password.
      // Reauthenticate the same UID with the verified Google credential so the
      // server can trust the token instead of client-side providerData flags.
      await refreshed.reauthenticateWithCredential(credential);
      await refreshed.reload();
      final authenticated = currentUser;
      if (authenticated == null || authenticated.uid != user.uid) {
        throw const SocialAuthException('account-changed');
      }
      await authenticated.getIdToken(true);
      await _verifySignedInUser(authenticated, expectedProvider: 'google.com');
    }, allowSignedIn: true);
  }

  static Future<bool> signInWithProvider(String provider) {
    if (!AccountIdentityPolicy.socialProviders.contains(provider)) {
      throw const SocialAuthException('provider-disabled');
    }
    return _authenticate(() async {
      if (!browserConfigured) {
        throw const SocialAuthException('server-url-missing');
      }
      final random = Random.secure();
      final verifier = base64UrlEncode(
        List<int>.generate(32, (_) => random.nextInt(256)),
      ).replaceAll('=', '');
      final challenge = base64UrlEncode(
        (await Sha256().hash(ascii.encode(verifier))).bytes,
      ).replaceAll('=', '');
      final started = await _call({
        'action': 'start',
        'provider': provider,
        'codeChallenge': challenge,
      });
      final session = started['session'];
      final authorizationUrl = started['authorizationUrl'];
      final uri = SocialAuthAuthorizationPolicy.validate(
        authorizationUrl,
        provider: provider,
        callbackUrl: endpoint,
      );
      if (!SocialAuthAuthorizationPolicy.isOpaqueSession(session) ||
          uri == null) {
        throw const SocialAuthException('invalid-callback');
      }
      final String callback;
      try {
        callback = await FlutterWebAuth2.authenticate(
          url: uri.toString(),
          callbackUrlScheme: SocialAuthCallbackPolicy.callbackScheme,
        );
      } on PlatformException catch (error) {
        if ({'canceled', 'cancelled'}.contains(error.code.toLowerCase())) {
          rethrow;
        }
        throw const SocialAuthException('browser-open-failed');
      } on MissingPluginException {
        throw const SocialAuthException('browser-open-failed');
      }
      final callbackError = SocialAuthCallbackPolicy.errorFor(
        callback,
        expectedSession: session as String,
      );
      if (callbackError != null) throw SocialAuthException(callbackError);
      if (currentUser != null) {
        throw const SocialAuthException('account-changed');
      }
      final exchanged = await _call({
        'action': 'exchange',
        'session': session,
        'codeVerifier': verifier,
      });
      final customToken = exchanged['customToken'];
      if (customToken is! String ||
          customToken.isEmpty ||
          exchanged['provider'] != provider) {
        throw const SocialAuthException('invalid-callback');
      }
      if (currentUser != null) {
        throw const SocialAuthException('account-changed');
      }
      final result = await FirebaseAuth.instance.signInWithCustomToken(
        customToken,
      );
      await _verifySignedInUser(
        result.user,
        expectedProvider: 'custom',
        expectedSocialProvider: provider,
      );
    });
  }

  static Future<void> _verifySignedInUser(
    User? user, {
    required String expectedProvider,
    String? expectedSocialProvider,
  }) async {
    if (user == null || currentUser?.uid != user.uid) {
      throw const SocialAuthException('account-changed');
    }
    final token = await user.getIdTokenResult(true);
    if (currentUser?.uid != user.uid) {
      throw const SocialAuthException('account-changed');
    }
    if (token.signInProvider != expectedProvider ||
        (expectedSocialProvider != null &&
            token.claims?['garden_social_provider'] !=
                expectedSocialProvider) ||
        !AccountIdentityPolicy.isTrusted(
          isAnonymous: user.isAnonymous,
          emailVerified: user.emailVerified,
          signInProvider: token.signInProvider,
          claims: token.claims,
        )) {
      throw const SocialAuthException('identity-not-verified');
    }
  }

  static Future<bool> _authenticate(
    Future<void> Function() action, {
    bool allowSignedIn = false,
  }) async {
    if (!firebaseReady) throw const SocialAuthException('firebase-not-ready');
    if (!supportsQuickLogin) {
      throw const SocialAuthException('unsupported-platform');
    }
    if (!allowSignedIn && signedIn) {
      throw const SocialAuthException('already-signed-in');
    }
    if (_authInProgress) throw const SocialAuthException('login-in-progress');
    _authInProgress = true;
    try {
      await action();
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const SocialAuthException('client-configuration');
      }
      throw const SocialAuthException('temporarily-unavailable');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw const SocialAuthException('provider-credential-invalid');
      }
      if ({
        'invalid-api-key',
        'app-not-authorized',
        'invalid-oauth-client-id',
      }.contains(e.code)) {
        throw const SocialAuthException('client-configuration');
      }
      rethrow;
    } on PlatformException catch (e) {
      if ({'canceled', 'cancelled'}.contains(e.code.toLowerCase())) {
        return false;
      }
      rethrow;
    } on SocialAuthException catch (e) {
      if (e.code == 'login-cancelled') return false;
      rethrow;
    } finally {
      _authInProgress = false;
    }
  }

  static Future<Map<String, dynamic>> _call(Map<String, dynamic> body) async {
    if (!browserConfigured) {
      throw const SocialAuthException('server-url-missing');
    }
    String? appCheck;
    try {
      appCheck = await FirebaseAppCheck.instance.getToken().timeout(
        const Duration(seconds: 15),
      );
    } on TimeoutException {
      throw const SocialAuthException('app-check-timeout');
    } catch (_) {
      // Preserve attestation: a failed check must never fall back to an
      // unauthenticated request. Do not expose token/provider exception text.
      throw const SocialAuthException('app-check-required');
    }
    if (appCheck == null || appCheck.isEmpty) {
      throw const SocialAuthException('app-check-required');
    }
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'X-Firebase-AppCheck': appCheck,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));
    } on TimeoutException {
      throw const SocialAuthException('auth-server-timeout');
    } on http.ClientException {
      throw const SocialAuthException('auth-server-unreachable');
    }
    if (response.statusCode == 404) {
      throw const SocialAuthException('auth-server-not-found');
    }
    dynamic parsed;
    try {
      parsed = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const SocialAuthException('auth-server-rejected');
      }
      throw const SocialAuthException('auth-server-response-invalid');
    }
    if (parsed is! Map) {
      throw const SocialAuthException('auth-server-response-invalid');
    }
    if (response.statusCode != 200) {
      throw SocialAuthException(
        parsed['error']?.toString() ??
            ((response.statusCode == 401 || response.statusCode == 403)
                ? 'auth-server-rejected'
                : 'temporarily-unavailable'),
      );
    }
    return Map<String, dynamic>.from(parsed);
  }

  static Future<void> signOut() async {
    // Stop uploads before changing the account. Existing local records and the
    // backup owner binding remain; logging in never silently transfers them.
    await GardenPushService.instance.beforeSignOut();
    await AutoBackupService.instance.disable();
    if (firebaseReady) await FirebaseAuth.instance.signOut();
    if (_googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase sign-out remains authoritative even when the provider SDK
        // cannot clear its chooser cache while offline.
      }
    }
  }

  static String messageFor(Object error) {
    if (error is SocialAuthException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => tr("이메일 주소를 확인해 주세요."),
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => tr("이메일과 비밀번호를 확인해 주세요."),
        'account-exists-with-different-credential' || 'email-already-in-use' =>
          tr("이미 이용하던 계정이 있어요. 기존 로그인 방법으로 접속해 주세요. 계정과 구매 내역은 자동으로 합치지 않아요."),
        'credential-already-in-use' => tr(
          "이 Google 계정은 다른 마음냥 계정에 연결되어 있어요. 기존 계정으로 로그인해 주세요.",
        ),
        'provider-already-linked' => tr("이 계정에는 이미 Google 로그인이 연결되어 있어요."),
        'invalid-custom-token' || 'custom-token-mismatch' => tr(
          "로그인 서버 연결을 확인하지 못했어요. 최신 앱인지 확인한 뒤 다시 시도해 주세요.",
        ),
        'requires-recent-login' => tr("안전한 처리를 위해 로그아웃한 뒤 다시 로그인해 주세요."),
        'too-many-requests' => tr("잠시 쉬었다가 다시 시도해 주세요."),
        'user-disabled' => tr("이용이 중지된 계정이에요. 문의해 주세요."),
        'operation-not-allowed' => tr("이 로그인 방식은 아직 연결 준비 중이에요."),
        'network-request-failed' => tr("인터넷 연결을 확인하고 다시 시도해 주세요."),
        _ => tr("로그인을 완료하지 못했어요. 다시 시도해 주세요."),
      };
    }
    if (error is TimeoutException)
      return tr("응답이 늦어지고 있어요. 연결을 확인하고 다시 시도해 주세요.");
    return tr("완료하지 못했어요. 연결을 확인하고 다시 시도해 주세요.");
  }
}
