import '../l10n/app_language.dart';
import 'companion_coat.dart';

class VisitingCat {
  final CompanionCoat coat;
  final int stage;
  final String name;
  const VisitingCat({
    required this.coat,
    required this.stage,
    required this.name,
  });
  double get scale => const [.82, .88, .94, 1.0][stage];
  Map<String, dynamic> toJson() => {
    'coat': coat.name,
    'stage': stage,
    'name': name,
  };
  factory VisitingCat.fromJson(dynamic raw) {
    if (raw is! Map ||
        CompanionCoat.parse(raw['coat']) == null ||
        raw['stage'] is! int ||
        raw['stage'] < 0 ||
        raw['stage'] > 3 ||
        raw['name'] is! String ||
        (raw['name'] as String).isEmpty) {
      throw FormatException(tr("방문 고양이를 확인하지 못했어요."));
    }
    return VisitingCat(
      coat: CompanionCoat.parse(raw['coat'])!,
      stage: raw['stage'],
      name: raw['name'],
    );
  }
}

class CatVisit {
  final String id, hostId, guestId;
  final String? hostNickname, guestNickname;
  final VisitingCat hostCat;
  final VisitingCat? guestCat;
  final DateTime? visitedAt;
  const CatVisit({
    required this.id,
    required this.hostId,
    required this.guestId,
    required this.hostCat,
    this.guestCat,
    this.hostNickname,
    this.guestNickname,
    this.visitedAt,
  });
  factory CatVisit.fromJson(dynamic raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        raw['hostId'] is! String ||
        raw['guestId'] is! String) {
      throw FormatException(tr("초대장을 확인하지 못했어요."));
    }
    return CatVisit(
      id: raw['id'],
      hostId: raw['hostId'],
      guestId: raw['guestId'],
      hostNickname: raw['hostNickname'] as String?,
      guestNickname: raw['guestNickname'] as String?,
      hostCat: VisitingCat.fromJson(raw['hostCat']),
      guestCat: raw['guestCat'] == null
          ? null
          : VisitingCat.fromJson(raw['guestCat']),
      visitedAt: raw['visitedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(raw['visitedAt'])
          : null,
    );
  }
}

class CatVisitInbox {
  final List<CatVisit> invitations, memories, sent;
  CatVisitInbox.fromJson(Map<String, dynamic> raw)
    : sent = ((raw['sent'] as List?) ?? []).map(CatVisit.fromJson).toList(),
      invitations = (raw['invitations'] as List)
          .map(CatVisit.fromJson)
          .toList(),
      memories = (raw['memories'] as List).map(CatVisit.fromJson).toList();
}
