/// A publication result belongs to one authenticated account. A missing or
/// failed response is unknown; it must never be interpreted as private.
class PublicGardenStatusSnapshot {
  final bool published;
  final String? nickname;
  const PublicGardenStatusSnapshot(this.published, this.nickname);

  factory PublicGardenStatusSnapshot.fromJson(Map<String, dynamic> value) {
    final published = value['published'];
    final nickname = value['nickname'];
    if (published is! bool || (nickname != null && nickname is! String)) {
      throw const FormatException('정원 공개 상태를 확인하지 못했어요.');
    }
    return PublicGardenStatusSnapshot(published, nickname as String?);
  }
}

/// Request generations prevent a previous account or an older request from
/// replacing a newer decision. Persisted hints cannot establish publication.
class PublicGardenStatus {
  String? owner;
  bool? published;
  String? nickname;
  bool loading = false;
  int _generation = 0;

  void selectOwner(String? uid, {String? cachedNickname}) {
    _generation++;
    owner = uid;
    published = null;
    nickname = cachedNickname;
    loading = false;
  }

  int begin(String uid) {
    if (owner != uid) selectOwner(uid);
    published = null;
    loading = true;
    return ++_generation;
  }

  bool apply(int request, String uid, PublicGardenStatusSnapshot snapshot) {
    if (owner != uid || request != _generation) return false;
    published = snapshot.published;
    nickname = snapshot.nickname;
    loading = false;
    return true;
  }

  bool fail(int request, String uid) {
    if (owner != uid || request != _generation) return false;
    published = null;
    loading = false;
    return true;
  }
}
