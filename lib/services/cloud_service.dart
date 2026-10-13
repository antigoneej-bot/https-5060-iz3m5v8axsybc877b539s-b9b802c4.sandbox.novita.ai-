import 'dart:convert';
import 'dart:math';
import '../mongi/models/public_garden_status.dart';
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

  // ── 3단계: 공개정원 / 응원 (opt-in, 서버 연결이 없으면 모든 메서드가
  // [enabled]==false라서 호출부에서 사전에 걸러지며, 여기서도 다시 한 번
  // StateError를 던져 안전하게 막는다) ─────────────────────────────

  /// 현재 로그인 계정의 서버 공개 여부를 확인한다. 조회 실패는 비공개가 아니다.
  static Future<PublicGardenStatusSnapshot> getMyPublicGardenStatus({
    required String owner,
  }) async => PublicGardenStatusSnapshot.fromJson(
    await call('getMyPublicGardenStatus', const {}, owner),
  );

  /// 씨앗·장식·성장 단계만 공개한다. 개인 기록은 서버 스키마에서 거부한다.
  static Future<PublicGardenStatusSnapshot> publishGarden({
    required String owner,
    Map<String, dynamic>? layout,
    required Map<String, int> seedCounts,
    required List<String> equippedDecorationIds,
    required int treeStageIndex,
    int memoryTreeStage = 0,
    bool hasCheerFlowers = false,
    List<String> flowerKinds = const [],
    String? nickname,
  }) async {
    final result = await call('publishGarden', {
      'snapshot': {
        if (layout != null) 'layout': layout,
        'seedCounts': seedCounts,
        'equippedDecorationIds': equippedDecorationIds,
        'treeStageIndex': treeStageIndex,
        'memoryTreeStage': memoryTreeStage,
        'hasCheerFlowers': hasCheerFlowers,
        'flowerKinds': flowerKinds,
      },
      if (nickname != null) 'nickname': nickname,
    }, owner);
    return PublicGardenStatusSnapshot.fromJson(result);
  }

  /// 공개를 멈춘다. 방문자 목록에서 즉시 사라진다.
  static Future<PublicGardenStatusSnapshot> unpublishGarden({
    required String owner,
  }) async => PublicGardenStatusSnapshot.fromJson(
    await call('unpublishGarden', const {}, owner),
  );

  /// 다른 사람들이 공개한 정원을 무작위 순서로 가져온다(인기순/최신순
  /// 정렬 없음 - 순서 자체가 매번 새로 섞인다).
  static Future<List<Map<String, dynamic>>> listPublicGardens() async {
    final result = await call('listPublicGardens');
    final gardens = result['gardens'];
    if (gardens is! List) return [];
    return gardens.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 특정 공개정원에 응원 꽃과 이모티콘을 보낸다.
  /// 같은 상대에게는 하루에 한 번만 보낼 수 있다(서버가 강제).
  static Future<void> sendPublicCheer({
    required String gardenId,
    required int messageIndex,
    int giftLightEssence = 0,
    String flowerKind = 'daisy',
    String? reaction,
  }) => call('sendPublicCheer', {
    'gardenId': gardenId,
    'messageIndex': messageIndex,
    'flowerKind': flowerKind,
    'reaction': reaction,
    'giftLightEssence': giftLightEssence,
  });

  /// 내가 아직 확인하지 않은(claim하지 않은) 받은 응원 목록.
  static Future<List<Map<String, dynamic>>> listMyCheers() async {
    final result = await call('listMyCheers');
    final cheers = result['cheers'];
    if (cheers is! List) return [];
    return cheers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// 받은 응원 하나를 확인 처리하고, 함께 온 빛의 정수 선물을 수령한다.
  /// 이미 확인한 응원이면 서버가 0을 돌려준다(중복 지급 방지).
  static Future<void> confirmFlowerPlanted(String id, String flowerKind) async {
    final result = await call('confirmFlowerPlanted', {
      'id': id,
      'flowerKind': flowerKind,
    });
    if (result['confirmed'] != true) throw StateError('꽃 소식을 확인하지 못했어요.');
  }

  static Future<List<Map<String, dynamic>>> listFlowerBlooms() async {
    final result = await call('listFlowerBlooms');
    return (result['blooms'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<String>? _deliveryDevicePending;

  /// Installation-scoped ID is deliberately excluded from garden backups.
  /// A pending legacy currency gift may only finish on its claiming device.
  static Future<String> cheerDeliveryDevice() =>
      _deliveryDevicePending ??= _loadDeliveryDevice().whenComplete(() {
        _deliveryDevicePending = null;
      });

  static Future<String> _loadDeliveryDevice() async {
    const key = 'cheer_delivery_device_v1';
    final stored = await _secure.read(key: key);
    if (stored != null && RegExp(r'^[a-zA-Z0-9_-]{32,128}$').hasMatch(stored)) {
      return stored;
    }
    final random = Random.secure();
    final id = List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _secure.write(key: key, value: id);
    return id;
  }

  static Future<({int amount, String? receipt})> claimCheer(
    String id, {
    required String owner,
    required String deviceId,
  }) async {
    final result = await call('claimCheerV2', {
      'id': id,
      'deviceId': deviceId,
    }, owner);
    final amount = result['amount'];
    final receipt = result['receipt'];
    if (result['claimed'] != true ||
        amount is! int ||
        amount < 0 ||
        amount > 5 ||
        (amount > 0 && receipt == null) ||
        (receipt != null &&
            (receipt is! String ||
                !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(receipt)))) {
      throw const CloudException('invalid-delivery-receipt');
    }
    return (amount: amount, receipt: receipt as String?);
  }

  static Future<void> acknowledgeCheer(
    String id,
    String receipt, {
    required String owner,
    required String deviceId,
  }) async {
    final result = await call('ackCheer', {
      'id': id,
      'receipt': receipt,
      'deviceId': deviceId,
    }, owner);
    if (result['acknowledged'] != true) {
      throw const CloudException('temporarily-unavailable');
    }
  }

  // ── 정원소식(= 기존 "공지") 관리자 CRUD + 경량 예약 ────────────────
  // 조회는 모든 로그인 사용자가 할 수 있고, 작성/수정/삭제는 관리자
  // 계정만 서버에서 허용한다(클라이언트의 관리자 메뉴 노출 여부와 무관하게
  // 서버가 다시 검증한다 - [SubscriptionService.isAdminUser]는 UI 노출
  // 여부를 판단할 때만 쓰고, 보안 경계로 신뢰하지 않는다).

  /// 정원소식 전체 목록(최신순, 최대 50개)을 가져온다.
  static Future<List<Map<String, dynamic>>> listGardenNews() async {
    final result = await call('listGardenNews');
    final news = result['news'];
    if (news is! List) return [];
    return news.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// (관리자 전용) 새 정원소식을 작성한다. [capacity]가 null이 아니면
  /// 앱 안에서 선착순 예약을 받는 소식이 된다.
  static Future<String> adminCreateGardenNews(Map<String, dynamic> news) async {
    final result = await call('adminCreateGardenNews', {'news': news});
    return result['id']?.toString() ?? '';
  }

  /// (관리자 전용) 기존 정원소식을 수정한다.
  static Future<void> adminUpdateGardenNews(
    String id,
    Map<String, dynamic> news,
  ) => call('adminUpdateGardenNews', {'id': id, 'news': news});

  /// (관리자 전용) 정원소식을 삭제한다. 이 소식의 예약 신청 기록도 함께
  /// 정리된다.
  static Future<void> adminDeleteGardenNews(String id) =>
      call('adminDeleteGardenNews', {'id': id});

  /// (관리자 전용) 특정 소식의 예약 신청자 목록(이메일/메모/신청시간)을
  /// 가져온다. 이름/연락처 등은 애초에 수집하지 않으므로 포함되지 않는다.
  static Future<List<Map<String, dynamic>>> adminListGardenNewsReservations(
    String newsId,
  ) async {
    final result = await call('adminListGardenNewsReservations', {
      'newsId': newsId,
    });
    final reservations = result['reservations'];
    if (reservations is! List) return [];
    return reservations
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  /// 선착순 예약을 신청한다. 정원이 다 찼거나 이미 신청했거나 마감된
  /// 소식이면 서버가 거부한다(중복신청/초과신청 방지).
  static Future<void> reserveGardenNews(String newsId, {String? note}) => call(
    'reserveGardenNews',
    {'newsId': newsId, if (note != null) 'note': note},
  );

  /// 신청을 취소한다. 신청한 적이 없으면 조용히 아무 일도 하지 않는다
  /// (멱등적 동작).
  static Future<void> cancelGardenNewsReservation(String newsId) =>
      call('cancelGardenNewsReservation', {'newsId': newsId});

  /// 내가 이미 신청한 정원소식 id 목록 (버튼을 "신청하기"/"신청 취소"로
  /// 구분해 보여주는 데 사용한다).
  static Future<Set<String>> myGardenNewsReservations() async {
    final result = await call('myGardenNewsReservations');
    final ids = result['newsIds'];
    if (ids is! List) return {};
    return ids.map((e) => e.toString()).toSet();
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
    'authentication-required' => '로그인 상태를 확인한 뒤 다시 시도해 주세요.',
    'currency-gifts-unavailable' => '지금은 꽃과 이모티콘으로 응원을 전할 수 있어요.',
    'client-update-required' => '앱을 업데이트한 뒤 선물을 받아 주세요.',
    'delivery-other-device' =>
      '이 선물은 다른 기기에서 받는 중이에요. 처음 수령한 기기에서 다시 시도해 주세요. 그 기기를 사용할 수 없다면 문의해 주세요.',
    'invalid-delivery-device' => '이 기기의 선물 수령 정보를 확인하지 못했어요. 다시 시도해 주세요.',
    'invalid-delivery-receipt' => '선물 수령을 확인하지 못했어요. 다시 시도해 주세요.',
    'cheer-not-found' => '이 응원을 찾을 수 없어요. 목록을 새로고침해 주세요.',
    'verify-email' => '이메일 인증을 완료한 뒤 다시 시도해 주세요.',
    'subscription-required' =>
      '자동 백업은 구독 중에 이용할 수 있어요. 수동 백업과 기존 백업 복원은 계속 가능해요.',
    'purchase-migration-required' => '이전 구독을 계정에 연결하려면 확인이 필요해요. 문의해 주세요.',
    'purchase-owner-mismatch' => '이 구매는 다른 계정에 연결되어 있어요.',
    'rate-limit' => '잠시 후 다시 시도해 주세요.',
    'recent-login-required' => '계정 삭제 전 다시 로그인해 주세요.',
    'cheer-already-sent-today' => '이 정원에는 오늘 이미 응원을 보냈어요. 내일 다시 전해주세요.',
    'garden-not-found' => '정원을 찾을 수 없어요. 방금 전 다른 분이 공개를 멈췄을 수 있어요.',
    'cannot-cheer-self' => '내 정원에는 응원을 보낼 수 없어요.',
    'invalid-snapshot' => '정원 정보를 공개하는 데 문제가 있었어요. 잠시 후 다시 시도해 주세요.',
    'admin-required' => '관리자 계정만 할 수 있어요.',
    'invalid-news' => '소식 내용을 다시 확인해 주세요.',
    'news-not-found' => '이 소식을 찾을 수 없어요. 방금 삭제되었을 수 있어요.',
    'already-reserved' => '이미 신청한 소식이에요.',
    'reservation-closed' => '이 소식은 신청이 마감되었어요.',
    'reservation-not-available' => '이 소식은 예약을 받지 않아요.',
    'reservation-full' => '신청 인원이 모두 찼어요.',
    _ => '서버 연결을 확인할 수 없어요. 잠시 후 다시 시도해 주세요.',
  };
}
