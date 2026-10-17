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
    'not-configured' ||
    'provider-disabled' ||
    'client-configuration' => '이 로그인 방식은 아직 연결 준비 중이에요. 다른 방법을 선택해 주세요.',
    'unsupported-platform' => '간편로그인은 현재 안드로이드 앱에서 이용할 수 있어요.',
    'already-signed-in' => '현재 계정을 먼저 로그아웃한 뒤 다른 계정으로 로그인해 주세요.',
    'account-changed' => '로그인 계정이 바뀌었어요. 현재 계정을 확인해 주세요.',
    'session-expired' || 'session-used' => '로그인 시간이 지났어요. 다시 시작해 주세요.',
    'invalid-callback' || 'invalid-proof' => '로그인 확인에 실패했어요. 앱에서 다시 시작해 주세요.',
    'app-check-required' => '이 앱의 인증을 확인하지 못했어요. 최신 테스트 앱인지 확인해 주세요.',
    'identity-not-verified' => '계정 인증을 확인하지 못했어요. 로그아웃 후 다시 로그인해 주세요.',
    'provider-credential-invalid' =>
      '선택한 로그인 계정의 인증이 만료되었어요. 간편로그인을 다시 시작해 주세요.',
    'account-deleting' ||
    'account-busy' => '계정 처리가 진행 중이에요. 잠시 후 로그인을 다시 시작해 주세요.',
    'account-disabled' => '이용이 중지된 계정이에요. 문의해 주세요.',
    'rate-limit' => '요청이 많아요. 잠시 후 로그인을 다시 시작해 주세요.',
    'login-restart-required' => '로그인을 처음부터 다시 시작해 주세요.',
    'account-deleted' => '삭제된 계정이에요. 계정 복구가 필요하면 문의해 주세요.',
    'login-in-progress' => '로그인이 진행 중이에요.',
    _ => '로그인을 완료하지 못했어요. 연결을 확인하고 다시 시도해 주세요.',
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
    if (user == null) return '로그인 전';
    final token = await user.getIdTokenResult();
    if (currentUser?.uid != user.uid) return '계정';
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
      if (!browserConfigured) throw const SocialAuthException('not-configured');
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
      final callback = await FlutterWebAuth2.authenticate(
        url: uri.toString(),
        callbackUrlScheme: SocialAuthCallbackPolicy.callbackScheme,
      );
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
    if (!firebaseReady) throw const SocialAuthException('not-configured');
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
    if (!browserConfigured) throw const SocialAuthException('not-configured');
    final appCheck = await FirebaseAppCheck.instance.getToken();
    if (appCheck == null || appCheck.isEmpty) {
      throw const SocialAuthException('app-check-required');
    }
    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-Firebase-AppCheck': appCheck,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 40));
    dynamic parsed;
    try {
      parsed = jsonDecode(response.body);
    } catch (_) {
      throw const SocialAuthException('temporarily-unavailable');
    }
    if (parsed is! Map) {
      throw const SocialAuthException('temporarily-unavailable');
    }
    if (response.statusCode != 200) {
      throw SocialAuthException(
        parsed['error']?.toString() ?? 'temporarily-unavailable',
      );
    }
    return Map<String, dynamic>.from(parsed);
  }

  static Future<void> signOut() async {
    // Stop uploads before changing the account. Existing local records and the
    // backup owner binding remain; logging in never silently transfers them.
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
        'invalid-email' => '이메일 주소를 확인해 주세요.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => '이메일과 비밀번호를 확인해 주세요.',
        'account-exists-with-different-credential' || 'email-already-in-use' =>
          '이미 이용하던 계정이 있어요. 기존 로그인 방법으로 접속해 주세요. 계정과 구매 내역은 자동으로 합치지 않아요.',
        'credential-already-in-use' =>
          '이 Google 계정은 다른 마음냥 계정에 연결되어 있어요. 기존 계정으로 로그인해 주세요.',
        'provider-already-linked' => '이 계정에는 이미 Google 로그인이 연결되어 있어요.',
        'invalid-custom-token' || 'custom-token-mismatch' =>
          '로그인 서버 연결을 확인하지 못했어요. 최신 앱인지 확인한 뒤 다시 시도해 주세요.',
        'requires-recent-login' => '안전한 처리를 위해 로그아웃한 뒤 다시 로그인해 주세요.',
        'too-many-requests' => '잠시 쉬었다가 다시 시도해 주세요.',
        'user-disabled' => '이용이 중지된 계정이에요. 문의해 주세요.',
        'operation-not-allowed' => '이 로그인 방식은 아직 연결 준비 중이에요.',
        'network-request-failed' => '인터넷 연결을 확인하고 다시 시도해 주세요.',
        _ => '로그인을 완료하지 못했어요. 다시 시도해 주세요.',
      };
    }
    if (error is TimeoutException) return '응답이 늦어지고 있어요. 연결을 확인하고 다시 시도해 주세요.';
    return '완료하지 못했어요. 연결을 확인하고 다시 시도해 주세요.';
  }
}
