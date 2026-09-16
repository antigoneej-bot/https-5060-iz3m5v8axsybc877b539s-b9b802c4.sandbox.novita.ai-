import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cryptography/cryptography.dart';

class CloudService {
  static final entitlementChanges = ValueNotifier<int>(0);
  static const endpoint = String.fromEnvironment('GARDEN_BACKEND_URL');
  static bool get enabled {
    final uri = Uri.tryParse(endpoint);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static const _secure = FlutterSecureStorage();
  static Future<Map<String, dynamic>> call(
    String action, [
    Map<String, dynamic> params = const {},
    String? expectedUid,
  ]) async {
    final uri = Uri.tryParse(endpoint);
    if (uri == null || uri.scheme != 'https')
      throw StateError('서버 연결 준비가 필요해요.');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('먼저 로그인해 주세요.');
    if (expectedUid != null && user.uid != expectedUid)
      throw const CloudException('account-changed');
    if ({'backup', 'listBackups', 'downloadBackup'}.contains(action))
      await ensureGardenOwner(user.uid);
    final token = await user.getIdToken();
    final appCheck = await FirebaseAppCheck.instance.getToken();
    if (token == null || appCheck == null)
      throw StateError('로그인 상태를 다시 확인해 주세요.');
    if (FirebaseAuth.instance.currentUser?.uid != user.uid)
      throw const CloudException('account-changed');
    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'X-Firebase-AppCheck': appCheck,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'action': action, ...params}),
        )
        .timeout(const Duration(seconds: 50));
    if (FirebaseAuth.instance.currentUser?.uid != user.uid)
      throw const CloudException('account-changed');
    if (response.statusCode != 200) {
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (_) {
        throw const CloudException('temporarily-unavailable');
      }
      throw CloudException(
        body is Map
            ? body['error']?.toString() ?? 'temporarily-unavailable'
            : 'temporarily-unavailable',
      );
    }
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> ensureGardenOwner(String uid, {bool bind = false}) async {
    final owner = await _secure.read(key: 'garden_cloud_owner');
    if (owner != null && owner != uid)
      throw const CloudException('garden-owner-mismatch');
    if (FirebaseAuth.instance.currentUser?.uid != uid)
      throw const CloudException('account-changed');
    if (bind && owner == null)
      await _secure.write(key: 'garden_cloud_owner', value: uid);
  }

  static Future<void> clearGardenOwner() =>
      _secure.delete(key: 'garden_cloud_owner');
  static Future<String> accountId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified)
      throw StateError('이메일 인증 후 구매해 주세요.');
    final hash = await Sha256().hash(utf8.encode(user.uid));
    return hash.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Future<Map<String, dynamic>> verify(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final result = await call('verify', {'token': token});
    if (uid != null && FirebaseAuth.instance.currentUser?.uid == uid) {
      await _secure.write(key: 'entitlement_$uid', value: jsonEncode(result));
      entitlementChanges.value++;
    }
    return result;
  }

  static Future<Map<String, dynamic>> refreshEntitlement() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final result = await call('status');
    if (uid != null && FirebaseAuth.instance.currentUser?.uid == uid) {
      await _secure.write(key: 'entitlement_$uid', value: jsonEncode(result));
      entitlementChanges.value++;
    }
    return result;
  }

  static Future<String> subscriptionStatusLabel() async {
    if (!enabled) return '무료 이용 중';
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '무료 이용 중';
    final raw = await _secure.read(key: 'entitlement_$uid');
    if (raw == null) return '무료 이용 중';
    try {
      final record = jsonDecode(raw) as Map;
      if (record['state'] == 'expired') return '구독 만료 · 기록과 아이템은 보관돼요';
      if (record['state'] == 'free') return '무료 이용 중';
      final expiry = DateTime.tryParse(record['expiresAt']?.toString() ?? '');
      if (expiry != null && !expiry.isAfter(DateTime.now()))
        return '구독 만료 · 기록과 아이템은 보관돼요';
      if (!await cachedPremium()) return '구독 상태 확인 필요';
      if (record['state'] == 'cancelScheduled')
        return '해지 예약 · 남은 이용 기간까지 사용 가능';
      if (record['state'] == 'trial') return '무료체험 이용 중';
      return '마음냥 구독 이용 중';
    } catch (_) {
      return '구독 상태 확인 필요';
    }
  }

  static Future<bool> cachedPremium() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final raw = await _secure.read(key: 'entitlement_$uid');
    if (raw == null) return false;
    try {
      final result = jsonDecode(raw);
      final now = DateTime.now().toUtc();
      final checked = DateTime.parse(result['checkedAt'] as String).toUtc();
      final expires = DateTime.parse(result['expiresAt'] as String).toUtc();
      return result['active'] == true &&
          expires.isAfter(now) &&
          !checked.isAfter(now.add(const Duration(minutes: 5))) &&
          now.difference(checked) < const Duration(hours: 48);
    } catch (_) {
      return false;
    }
  }
}

class CloudException implements Exception {
  final String code;
  const CloudException(this.code);
  @override
  String toString() => switch (code) {
    'garden-owner-mismatch' => '이 기기 정원은 다른 백업 계정에 연결되어 있어요. 원래 계정으로 로그인해 주세요.',
    'account-changed' => '작업 중 계정이 바뀌었어요. 다시 시도해 주세요.',
    'account-busy' => '이 계정의 다른 작업이 진행 중이에요. 잠시 후 다시 시도해 주세요.',
    'account-deleting' => '계정 삭제가 진행 중이에요. 삭제를 다시 시도해 마무리해 주세요.',
    'verify-email' => '이메일 인증을 완료한 뒤 다시 시도해 주세요.',
    'subscription-required' =>
      '자동 백업은 구독 중에 이용할 수 있어요. 수동 백업과 기존 백업 복원은 계속 가능해요.',
    'purchase-migration-required' => '이전 구독을 계정에 연결하려면 확인이 필요해요. 문의해 주세요.',
    'purchase-owner-mismatch' => '이 구매는 다른 계정에 연결되어 있어요.',
    'rate-limit' => '잠시 후 다시 시도해 주세요.',
    'recent-login-required' => '계정 삭제 전 다시 로그인해 주세요.',
    _ => '서버 연결을 확인할 수 없어요. 잠시 후 다시 시도해 주세요.',
  };
}
