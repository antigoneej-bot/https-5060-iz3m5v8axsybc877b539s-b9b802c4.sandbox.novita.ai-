import 'garden_village.dart';

/// A publication result belongs to one authenticated account. A missing or
/// failed response is unknown; it must never be interpreted as private.
class PublicGardenStatusSnapshot {
  final bool published;
  final String? nickname;
  final GardenVisibility? visibility;
  final bool? discoveryOptIn;
  final bool? receiveGifts;
  final Map<String, dynamic>? snapshot;
  final DateTime? updatedAt;
  const PublicGardenStatusSnapshot(
    this.published,
    this.nickname, {
    this.visibility,
    this.discoveryOptIn,
    this.receiveGifts,
    this.snapshot,
    this.updatedAt,
  });

  factory PublicGardenStatusSnapshot.fromJson(Map<String, dynamic> value) {
    final published = value['published'];
    final nickname = value['nickname'];
    final scope = value['visibility'];
    final matches = GardenVisibility.values.where((v) => v.name == scope);
    if (published is! bool ||
        (nickname != null && nickname is! String) ||
        (scope != null && matches.isEmpty) ||
        (scope == 'private' && published) ||
        (value['discoveryOptIn'] != null && value['discoveryOptIn'] is! bool) ||
        (value['receiveGifts'] != null && value['receiveGifts'] is! bool) ||
        (value['snapshot'] != null && value['snapshot'] is! Map) ||
        (value['updatedAt'] != null &&
            (value['updatedAt'] is! String ||
                DateTime.tryParse(value['updatedAt'] as String) == null))) {
      throw const FormatException('정원 공개 상태를 확인하지 못했어요.');
    }
    return PublicGardenStatusSnapshot(
      published,
      nickname as String?,
      visibility: scope == null ? null : matches.single,
      discoveryOptIn: value['discoveryOptIn'] as bool?,
      receiveGifts: value['receiveGifts'] as bool?,
      snapshot: value['snapshot'] == null
          ? null
          : Map<String, dynamic>.from(value['snapshot'] as Map),
      updatedAt: value['updatedAt'] == null
          ? null
          : DateTime.parse(value['updatedAt'] as String),
    );
  }
}

/// Request generations prevent a previous account or an older request from
/// replacing a newer decision. Persisted hints cannot establish publication.
class PublicGardenStatus {
  String? owner;
  bool? published;
  String? nickname;
  GardenVisibility? visibility;
  bool? discoveryOptIn;
  bool? receiveGifts;
  Map<String, dynamic>? snapshot;
  DateTime? updatedAt;
  bool loading = false;
  int _generation = 0;

  void selectOwner(String? uid, {String? cachedNickname}) {
    _generation++;
    owner = uid;
    published = null;
    nickname = cachedNickname;
    visibility = null;
    discoveryOptIn = null;
    receiveGifts = null;
    snapshot = null;
    updatedAt = null;
    loading = false;
  }

  int begin(String uid) {
    if (owner != uid) selectOwner(uid);
    published = null;
    visibility = null;
    discoveryOptIn = null;
    receiveGifts = null;
    snapshot = null;
    updatedAt = null;
    loading = true;
    return ++_generation;
  }

  bool apply(int request, String uid, PublicGardenStatusSnapshot snapshot) {
    if (owner != uid || request != _generation) return false;
    published = snapshot.published;
    nickname = snapshot.nickname;
    visibility = snapshot.visibility;
    discoveryOptIn = snapshot.discoveryOptIn;
    receiveGifts = snapshot.receiveGifts;
    this.snapshot = snapshot.snapshot;
    updatedAt = snapshot.updatedAt;
    loading = false;
    return true;
  }

  bool fail(int request, String uid) {
    if (owner != uid || request != _generation) return false;
    published = null;
    visibility = null;
    discoveryOptIn = null;
    receiveGifts = null;
    snapshot = null;
    updatedAt = null;
    loading = false;
    return true;
  }
}
