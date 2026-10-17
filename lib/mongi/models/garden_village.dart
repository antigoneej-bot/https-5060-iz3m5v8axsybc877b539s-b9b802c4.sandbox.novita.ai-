import 'public_garden.dart';

String? _nextCursor(Map<String, dynamic> json) {
  final cursor = json['nextCursor'];
  if (cursor != null &&
      (cursor is! String || cursor.isEmpty || cursor.length > 4096)) {
    throw const FormatException('다음 목록 정보를 확인하지 못했어요.');
  }
  return cursor as String?;
}

class PublicGardenPage {
  final List<PublicGarden> gardens;
  final String? nextCursor;
  const PublicGardenPage({this.gardens = const [], this.nextCursor});

  factory PublicGardenPage.fromJson(Map<String, dynamic> json) {
    final raw = json['gardens'];
    if (raw is! List || raw.any((entry) => entry is! Map)) {
      throw const FormatException('정원 목록을 확인하지 못했어요.');
    }
    return PublicGardenPage(
      gardens: List.unmodifiable(
        raw.map(
          (entry) =>
              PublicGarden.fromJson(Map<String, dynamic>.from(entry as Map)),
        ),
      ),
      nextCursor: _nextCursor(json),
    );
  }
}

enum GardenVisibility { private, neighbors, public }

class GardenVillageProfile {
  final String inviteCode;
  final GardenVisibility visibility;
  final bool discoveryOptIn;
  final bool receiveGifts;
  final String? nickname;

  const GardenVillageProfile({
    required this.inviteCode,
    required this.visibility,
    required this.discoveryOptIn,
    required this.receiveGifts,
    this.nickname,
  });

  factory GardenVillageProfile.fromJson(Map<String, dynamic> json) {
    final code = json['inviteCode'];
    final visibility = json['visibility'];
    final matches = GardenVisibility.values.where((v) => v.name == visibility);
    if (code is! String ||
        code.isEmpty ||
        matches.isEmpty ||
        json['discoveryOptIn'] is! bool ||
        json['receiveGifts'] is! bool ||
        (json['nickname'] != null && json['nickname'] is! String)) {
      throw const FormatException('냥이 마을 설정을 확인하지 못했어요.');
    }
    return GardenVillageProfile(
      inviteCode: code,
      visibility: matches.single,
      discoveryOptIn: json['discoveryOptIn'] as bool,
      receiveGifts: json['receiveGifts'] as bool,
      nickname: json['nickname'] as String?,
    );
  }
}

class GardenNeighbor {
  final String gardenId;
  final String? nickname;
  final String status;
  final DateTime? requestedAt;
  final bool? canVisit;

  const GardenNeighbor({
    required this.gardenId,
    this.nickname,
    this.status = 'none',
    this.requestedAt,
    this.canVisit,
  });

  String get displayName =>
      nickname?.trim().isNotEmpty == true ? nickname!.trim() : '이름 없는 정원사';

  factory GardenNeighbor.fromJson(Map<String, dynamic> json) {
    final id = json['gardenId'];
    if (id is! String || id.isEmpty || id.length > 128) {
      throw const FormatException('이웃 정보를 확인하지 못했어요.');
    }
    return GardenNeighbor(
      gardenId: id,
      nickname: json['nickname'] is String ? json['nickname'] as String : null,
      status: json['status'] is String ? json['status'] as String : 'none',
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? ''),
      canVisit: json['canVisit'] is bool ? json['canVisit'] as bool : null,
    );
  }
}

class GardenNeighborLists {
  final List<GardenNeighbor> neighbors;
  final List<GardenNeighbor> incoming;
  final List<GardenNeighbor> outgoing;
  final List<GardenNeighbor> blocked;

  const GardenNeighborLists({
    this.neighbors = const [],
    this.incoming = const [],
    this.outgoing = const [],
    this.blocked = const [],
  });

  factory GardenNeighborLists.fromJson(Map<String, dynamic> json) {
    List<GardenNeighbor> read(String key) {
      final value = json[key];
      if (value is! List || value.any((entry) => entry is! Map)) {
        throw const FormatException('이웃 목록을 확인하지 못했어요.');
      }
      return List.unmodifiable(
        value.map(
          (entry) =>
              GardenNeighbor.fromJson(Map<String, dynamic>.from(entry as Map)),
        ),
      );
    }

    return GardenNeighborLists(
      neighbors: read('neighbors'),
      incoming: read('incoming'),
      outgoing: read('outgoing'),
      blocked: read('blocked'),
    );
  }
}

/// Retired IDs are server-confirmed transfers. Absence from a limited inbox
/// page alone never means that a locally planted keepsake should disappear.
class ReceivedCheerBatch {
  final List<ReceivedCheer> cheers;
  final List<String> retiredIds;
  final String? nextCursor;
  const ReceivedCheerBatch({
    this.cheers = const [],
    this.retiredIds = const [],
    this.nextCursor,
  });

  factory ReceivedCheerBatch.fromJson(Map<String, dynamic> json) {
    final raw = json['cheers'];
    final retired = json['retiredIds'] ?? const [];
    if (raw is! List ||
        raw.any((entry) => entry is! Map) ||
        retired is! List ||
        retired.any((id) => id is! String || id.isEmpty || id.length > 128)) {
      throw const FormatException('받은 마음을 확인하지 못했어요.');
    }
    return ReceivedCheerBatch(
      cheers: List.unmodifiable(
        raw.map(
          (entry) =>
              ReceivedCheer.fromJson(Map<String, dynamic>.from(entry as Map)),
        ),
      ),
      retiredIds: List<String>.unmodifiable(retired.cast<String>()),
      nextCursor: _nextCursor(json),
    );
  }
}
