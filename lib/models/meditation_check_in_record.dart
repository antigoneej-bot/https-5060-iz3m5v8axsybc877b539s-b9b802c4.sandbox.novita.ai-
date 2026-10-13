import '../data/meditation_media_data.dart';

/// Self-reported change after a session, never an inferred health score.
class MeditationCheckInRecord {
  final String session, guide, feeling;
  final DateTime at;
  const MeditationCheckInRecord({
    required this.session,
    required this.guide,
    required this.feeling,
    required this.at,
  });

  factory MeditationCheckInRecord.fromMap(Map data) {
    final session = data['session'], guide = data['guide'];
    final feeling = data['feeling'], rawDate = data['at'];
    final at = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (session is! String ||
        session.trim().isEmpty ||
        session.length > 200 ||
        guide is! String ||
        !meditationMedia.containsKey(guide) ||
        !const {'better', 'same', 'worse'}.contains(feeling) ||
        at == null) {
      throw const FormatException('명상 후기 기록을 확인할 수 없어요.');
    }
    return MeditationCheckInRecord(
      session: session,
      guide: guide,
      feeling: feeling as String,
      at: at,
    );
  }

  Map<String, dynamic> toMap() => {
    'session': session,
    'guide': guide,
    'feeling': feeling,
    'at': at.toIso8601String(),
  };

  /// Validate the whole legacy set before writing anything. Preserve the first
  /// occurrence of a session, matching the old store's retry behavior.
  static List<MeditationCheckInRecord> parseLegacy(Object? raw) {
    if (raw is! List) throw const FormatException('명상 후기 목록이 올바르지 않아요.');
    final entries = <String, MeditationCheckInRecord>{};
    for (final row in raw) {
      if (row is! Map) throw const FormatException('명상 후기 항목이 올바르지 않아요.');
      final record = MeditationCheckInRecord.fromMap(row);
      entries.putIfAbsent(record.session, () => record);
    }
    return entries.values.toList();
  }
}
