/// A server-confirmed action, with no journal or private emotion payload.
class SharedTreeActivity {
  final String type;
  final bool mine, unread;
  final int version;
  final DateTime? createdAt;
  const SharedTreeActivity({
    required this.type,
    required this.mine,
    required this.unread,
    required this.version,
    this.createdAt,
  });
  factory SharedTreeActivity.fromJson(Map<String, dynamic> json) =>
      SharedTreeActivity(
        type: json['type'] as String,
        mine: json['mine'] == true,
        unread: json['unread'] == true,
        version: (json['version'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
  String get message => switch (type) {
    'invited' => mine ? '함께 가꾸는 초대를 보냈어요' : '함께 가꾸는 초대가 도착했어요',
    'accepted' => mine ? '초대를 수락했어요' : '이웃이 초대를 수락했어요',
    'declined' => mine ? '초대를 사양했어요' : '이웃이 이번 초대를 사양했어요',
    'watered' => mine ? '물 주고 다녀갔어요' : '이웃이 물을 주고 다녀갔어요',
    'note' => mine ? '마음 한 줄을 남겼어요' : '새 마음 한 줄이 도착했어요',
    _ => '함께 가꾸는 나무의 소식이에요',
  };
}

class MySharedTreeNote {
  final String treeId, id, text;
  final DateTime? createdAt;
  const MySharedTreeNote({
    required this.treeId,
    required this.id,
    required this.text,
    this.createdAt,
  });
  factory MySharedTreeNote.fromJson(Map<String, dynamic> json) =>
      MySharedTreeNote(
        treeId: json['treeId'] as String,
        id: json['id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class MySharedTreeNotePage {
  final List<MySharedTreeNote> notes;
  final String? nextCursor;
  const MySharedTreeNotePage(this.notes, this.nextCursor);
  factory MySharedTreeNotePage.fromJson(Map<String, dynamic> json) =>
      MySharedTreeNotePage(
        (json['notes'] as List)
            .map(
              (n) => MySharedTreeNote.fromJson(
                Map<String, dynamic>.from(n as Map),
              ),
            )
            .toList(),
        json['nextCursor'] as String?,
      );
}

/// A private, explicitly shared keepsake. Journal and emotion data are absent.
class SharedTreeNote {
  final String id, text;
  final String? authorName;
  final bool mine;
  final DateTime? createdAt;
  const SharedTreeNote({
    required this.id,
    required this.text,
    required this.mine,
    this.authorName,
    this.createdAt,
  });
  factory SharedTreeNote.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['text'] is! String ||
        json['mine'] is! bool) {
      throw const FormatException('함께 남긴 메모를 확인하지 못했어요.');
    }
    return SharedTreeNote(
      id: json['id'] as String,
      text: json['text'] as String,
      mine: json['mine'] as bool,
      authorName: json['authorName'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class SharedTree {
  final String id, name, anniversaryOn, myRole, status, guestStatus, style;
  final String? hostName, guestName, myLastWateredOn, neighborLastWateredOn;
  final DateTime? createdAt;
  final int activeDays, activityVersion, unreadCount;
  final List<SharedTreeActivity> activities;
  final bool wateredToday;
  final List<SharedTreeNote> notes;
  const SharedTree({
    required this.id,
    required this.name,
    required this.anniversaryOn,
    required this.myRole,
    required this.status,
    required this.guestStatus,
    this.style = 'sage',
    required this.activeDays,
    required this.wateredToday,
    required this.notes,
    this.hostName,
    this.guestName,
    this.createdAt,
    this.myLastWateredOn,
    this.neighborLastWateredOn,
    this.activityVersion = 0,
    this.unreadCount = 0,
    this.activities = const [],
  });
  bool get hasUnread => unreadCount > 0;
  bool get isHost => myRole == 'host';
  bool get isActive => status == 'active' && guestStatus == 'accepted';
  bool get isInvitation =>
      !isHost && status == 'invited' && guestStatus == 'invited';
  String get neighborName => (isHost ? guestName : hostName) ?? '이웃';
  String get stageLabel => activeDays >= 30
      ? '잎이 풍성한 나무'
      : activeDays >= 10
      ? '가지가 자라는 나무'
      : activeDays >= 3
      ? '어린 나무'
      : '첫 새싹';
  factory SharedTree.fromJson(Map<String, dynamic> json) {
    final requiredStrings = [
      'id',
      'name',
      'anniversaryOn',
      'myRole',
      'status',
      'guestStatus',
    ];
    if (requiredStrings.any((k) => json[k] is! String) ||
        !['host', 'guest'].contains(json['myRole']) ||
        !['invited', 'active', 'archived'].contains(json['status']) ||
        json['activeDays'] is! int ||
        (json['activeDays'] as int) < 0 ||
        json['wateredToday'] is! bool ||
        json['notes'] is! List ||
        (json['notes'] as List).any((n) => n is! Map)) {
      throw const FormatException('함께 가꾸는 나무를 확인하지 못했어요.');
    }
    return SharedTree(
      id: json['id'] as String,
      name: json['name'] as String,
      anniversaryOn: json['anniversaryOn'] as String,
      myRole: json['myRole'] as String,
      status: json['status'] as String,
      guestStatus: json['guestStatus'] as String,
      style:
          json['style'] is String &&
              ['sage', 'blossom', 'moonlight'].contains(json['style'])
          ? json['style'] as String
          : 'sage',
      activeDays: json['activeDays'] as int,
      activityVersion: (json['activityVersion'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      activities: (json['activities'] as List? ?? const [])
          .map(
            (a) => SharedTreeActivity.fromJson(
              Map<String, dynamic>.from(a as Map),
            ),
          )
          .toList(),
      wateredToday: json['wateredToday'] as bool,
      hostName: json['hostName'] as String?,
      guestName: json['guestName'] as String?,
      myLastWateredOn: json['myLastWateredOn'] as String?,
      neighborLastWateredOn: json['neighborLastWateredOn'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      notes: List.unmodifiable(
        (json['notes'] as List).map(
          (n) => SharedTreeNote.fromJson(Map<String, dynamic>.from(n as Map)),
        ),
      ),
    );
  }
}

class SharedTreePage {
  final List<SharedTree> trees;
  final String? nextCursor;
  const SharedTreePage(this.trees, this.nextCursor);
  factory SharedTreePage.fromJson(Map<String, dynamic> json) {
    if (json['trees'] is! List ||
        (json['trees'] as List).any((n) => n is! Map) ||
        (json['nextCursor'] != null && json['nextCursor'] is! String)) {
      throw const FormatException('함께 가꾸는 나무 목록을 확인하지 못했어요.');
    }
    return SharedTreePage(
      List.unmodifiable(
        (json['trees'] as List).map(
          (n) => SharedTree.fromJson(Map<String, dynamic>.from(n as Map)),
        ),
      ),
      json['nextCursor'] as String?,
    );
  }
}
