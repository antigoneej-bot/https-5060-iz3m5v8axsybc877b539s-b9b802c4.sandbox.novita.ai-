import '../models/cat_visit.dart';
import 'dart:math';

import '../mongi/models/garden_village.dart';
import '../mongi/models/public_garden.dart';
import 'cloud_service.dart';

typedef GardenVillageTransport =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> params,
      String owner,
    );

/// A screen's social requests belong to one signed-in account. A response from
/// an old account is never returned to a newly signed-in user. Create a fresh
/// instance when reopening the village after an account change.
class GardenVillageService {
  final GardenVillageTransport _transport;
  final String? Function() _currentOwner;
  final Future<void> Function(Duration) _retryDelay;
  String? _owner;

  GardenVillageService({
    GardenVillageTransport? transport,
    String? Function()? currentOwner,
    Future<void> Function(Duration)? retryDelay,
  }) : _transport = transport ?? _cloudTransport,
       _currentOwner = currentOwner ?? _cloudOwner,
       _retryDelay = retryDelay ?? _wait;

  static Future<void> _wait(Duration duration) =>
      Future<void>.delayed(duration);

  static Future<Map<String, dynamic>> _cloudTransport(
    String action,
    Map<String, dynamic> params,
    String owner,
  ) => CloudService.call(action, params, owner);

  static String? _cloudOwner() {
    final user = CloudService.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  String? get accountOwner => _owner ?? _currentOwner();

  String pinAccount() {
    final owner = _currentOwner();
    if (owner == null) throw const CloudException('authentication-required');
    if (_owner != null && _owner != owner)
      throw const CloudException('account-changed');
    _owner ??= owner;
    return owner;
  }

  Future<Map<String, dynamic>> _request(
    String action, [
    Map<String, dynamic> params = const {},
  ]) async {
    final owner = _currentOwner();
    if (owner == null) {
      throw const CloudException('authentication-required');
    }
    if (_owner != null && _owner != owner) {
      throw const CloudException('account-changed');
    }
    _owner ??= owner;
    return CloudService.retryAccountBusy(
      owner: owner,
      currentOwner: _currentOwner,
      wait: _retryDelay,
      action: () => _transport(action, params, owner),
    );
  }

  Future<Map<String, dynamic>> memoryCards(
    String action, [
    Map<String, dynamic> body = const {},
  ]) => _request(action, body);

  Future<Map<String, dynamic>> orchardState() => _request('getOrchard');
  Future<Map<String, dynamic>> orchardMutation(Map<String, dynamic> body) =>
      _request('mutateOrchard', body);

  Future<CatVisitInbox> listCatVisits() async =>
      CatVisitInbox.fromJson(await _request('listCatVisits'));
  Future<void> inviteCat(String gardenId, VisitingCat cat) async {
    await _request('inviteCatVisit', {
      'gardenId': _gardenId(gardenId),
      'cat': cat.toJson(),
    });
  }

  Future<CatVisit?> respondCat(CatVisit invitation, {VisitingCat? cat}) async {
    final raw = await _request('respondCatVisit', {
      'gardenId': _gardenId(invitation.hostId),
      'invitationId': invitation.id,
      'accept': cat != null,
      if (cat != null) 'cat': cat.toJson(),
    });
    return cat == null ? null : CatVisit.fromJson(raw['visit']);
  }

  Future<void> cancelCat(CatVisit invitation) async {
    await _request('cancelCatVisit', {
      'gardenId': _gardenId(invitation.guestId),
      'invitationId': invitation.id,
    });
  }

  Future<CatVisit> getCatVisit(String id) async => CatVisit.fromJson(
    (await _request('getCatVisit', {'visitId': id}))['visit'],
  );

  Future<GardenVillageProfile> getProfile() async =>
      GardenVillageProfile.fromJson(await _request('getVillageProfile'));

  Future<GardenVillageProfile> updateProfile({
    required GardenVisibility visibility,
    required bool discoveryOptIn,
    bool? randomVisitOptIn,
    required bool receiveGifts,
    String? nickname,
  }) async => GardenVillageProfile.fromJson(
    await _request('updateVillageProfile', {
      'visibility': visibility.name,
      'discoveryOptIn': visibility == GardenVisibility.public && discoveryOptIn,
      if (randomVisitOptIn != null)
        'randomVisitOptIn':
            visibility == GardenVisibility.public && randomVisitOptIn,
      'receiveGifts': receiveGifts,
      if (nickname != null) 'nickname': nickname.trim(),
    }),
  );

  Future<GardenNeighborLists> listNeighbors() async =>
      GardenNeighborLists.fromJson(await _request('listNeighbors'));

  Future<GardenNeighbor> lookupInvite(String inviteCode) async =>
      GardenNeighbor.fromJson(
        await _request('lookupNeighbor', {
          'inviteCode': _normalizeCode(inviteCode),
        }),
      );

  Future<void> requestNeighbor({String? inviteCode, String? gardenId}) async {
    if ((inviteCode == null) == (gardenId == null)) {
      throw ArgumentError('초대 코드 또는 정원 하나를 선택해 주세요.');
    }
    await _request('requestNeighbor', {
      if (inviteCode != null) 'inviteCode': _normalizeCode(inviteCode),
      if (gardenId != null) 'gardenId': _gardenId(gardenId),
    });
  }

  Future<void> respondNeighbor(String gardenId, {required bool accept}) async {
    await _request('respondNeighbor', {
      'gardenId': _gardenId(gardenId),
      'accept': accept,
    });
  }

  Future<void> removeNeighbor(String gardenId) async {
    await _request('removeNeighbor', {'gardenId': _gardenId(gardenId)});
  }

  Future<void> blockNeighbor(String gardenId, {bool blocked = true}) async {
    await _request('blockNeighbor', {
      'gardenId': _gardenId(gardenId),
      'blocked': blocked,
    });
  }

  Future<void> reportGarden(String gardenId, {required String reason}) async {
    if (!{
      'inappropriate_name',
      'harassment',
      'spam',
      'other',
    }.contains(reason)) {
      throw ArgumentError('신고 사유를 선택해 주세요.');
    }
    await _request('reportGarden', {
      'gardenId': _gardenId(gardenId),
      'reason': reason,
    });
  }

  Future<PublicGarden> getGarden(String gardenId) async {
    final id = _gardenId(gardenId);
    final result = await _request('getNeighborGarden', {'gardenId': id});
    final raw = result['garden'];
    if (raw is! Map || raw['gardenId'] != id) {
      throw const FormatException('이웃 정원을 확인하지 못했어요.');
    }
    return PublicGarden.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<List<PublicGarden>> listPublicGardens() async =>
      (await listPublicGardensPage()).gardens;

  Future<PublicGarden?> randomGarden() async {
    final raw = (await _request('randomPublicGarden'))['garden'];
    if (raw == null) return null;
    if (raw is! Map || raw['gardenId'] is! String)
      throw const FormatException('정원을 확인하지 못했어요.');
    return PublicGarden.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<PublicGarden> getPublicVisitGarden(String id) async {
    final result = await _request('getPublicVisitGarden', {
      'gardenId': _gardenId(id),
    });
    if (result['garden'] is! Map || result['garden']['gardenId'] != id)
      throw const FormatException('정원을 확인하지 못했어요.');
    return PublicGarden.fromJson(Map<String, dynamic>.from(result['garden']));
  }

  Future<void> setFavorite(String id, bool favorite) async {
    await _request('setFavoriteGarden', {
      'gardenId': _gardenId(id),
      'favorite': favorite,
    });
  }

  Future<PublicGardenPage> favoriteGardens({String? cursor}) async =>
      PublicGardenPage.fromJson(
        await _request('listFavoriteGardens', {
          if (cursor != null) 'cursor': cursor,
        }),
      );

  Future<PublicGardenPage> listPublicGardensPage({
    String? cursor,
    int pageSize = 12,
  }) async => PublicGardenPage.fromJson(
    await _request('listPublicGardens', {
      if (cursor != null) 'cursor': cursor,
      'pageSize': pageSize,
    }),
  );

  Future<ReceivedCheerBatch> listReceivedCheers({
    String? cursor,
    int pageSize = 80,
  }) async => ReceivedCheerBatch.fromJson(
    await _request('listMyCheers', {
      if (cursor != null) 'cursor': cursor,
      'pageSize': pageSize,
    }),
  );

  Future<void> sendCheer({
    required String gardenId,
    required int messageIndex,
    String flowerKind = 'daisy',
    String? reaction,
    String deliveryKind = 'cheer',
  }) async {
    if (deliveryKind != 'cheer' && deliveryKind != 'gift') {
      throw ArgumentError('보낼 마음의 종류를 확인해 주세요.');
    }
    await _request('sendPublicCheer', {
      'gardenId': _gardenId(gardenId),
      'messageIndex': messageIndex,
      'flowerKind': deliveryKind == 'gift' ? flowerKind : null,
      'reaction': reaction,
      'deliveryKind': deliveryKind,
      'giftLightEssence': 0,
    });
  }

  /// Transfers an existing, unplanted server gift. Callers retain requestId
  /// when retrying a failed response; the server commits at most one transfer.
  Future<void> sendGift({
    required String gardenId,
    required String sourceCheerId,
    required String requestId,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(requestId)) {
      throw ArgumentError('선물 전송 정보를 다시 확인해 주세요.');
    }
    final result = await _request('sendGardenGift', {
      'gardenId': _gardenId(gardenId),
      'sourceCheerId': _gardenId(sourceCheerId),
      'requestId': requestId,
    });
    if (result['sent'] != true || result['sourceCheerId'] != sourceCheerId) {
      throw const CloudException('invalid-delivery-receipt');
    }
  }

  static String createGiftRequestId() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static String _normalizeCode(String value) {
    final normalized = value.trim().toUpperCase().replaceAll(
      RegExp(r'[ -]'),
      '',
    );
    if (!RegExp(r'^[A-F0-9]{12}$').hasMatch(normalized)) {
      throw const CloudException('invalid-invite-code');
    }
    return normalized;
  }

  static String _gardenId(String value) {
    if (value.isEmpty || value.length > 128 || value.contains('/')) {
      throw const CloudException('garden-not-found');
    }
    return value;
  }
}
