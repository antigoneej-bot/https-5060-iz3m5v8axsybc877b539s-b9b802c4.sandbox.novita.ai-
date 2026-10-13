import '../data/meditation_media_data.dart';

/// A replayable local completion, captured before any reward/progress write.
class MeditationCompletionRecord {
  final String id;
  final DateTime completedAt;
  final String? guide, course;
  final int? index;
  final bool reward;
  const MeditationCompletionRecord({
    required this.id,
    required this.completedAt,
    this.guide,
    this.course,
    this.index,
    required this.reward,
  });
  DateTime get day =>
      DateTime(completedAt.year, completedAt.month, completedAt.day);
  Map<String, dynamic> toMap() => {
    'version': 1,
    'id': id,
    'at': completedAt.toIso8601String(),
    'guide': guide,
    'course': course,
    'index': index,
    'reward': reward,
  };
  factory MeditationCompletionRecord.fromMap(Map data) {
    final id = data['id'], rawDate = data['at'], guide = data['guide'];
    final course = data['course'], index = data['index'];
    final at = rawDate is String ? DateTime.tryParse(rawDate) : null;
    if (data['version'] != 1 ||
        id is! String ||
        id.isEmpty ||
        id.length > 200 ||
        at == null ||
        at.toIso8601String() != rawDate ||
        (guide != null &&
            (guide is! String || !meditationMedia.containsKey(guide))) ||
        data['reward'] is! bool ||
        (course == null && index != null) ||
        (course != null &&
            (course is! String ||
                index is! int ||
                index < 0 ||
                guide == null))) {
      throw const FormatException('명상 완료 기록을 확인할 수 없어요.');
    }
    return MeditationCompletionRecord(
      id: id,
      completedAt: at,
      guide: guide as String?,
      course: course as String?,
      index: index as int?,
      reward: data['reward'] as bool,
    );
  }
}
