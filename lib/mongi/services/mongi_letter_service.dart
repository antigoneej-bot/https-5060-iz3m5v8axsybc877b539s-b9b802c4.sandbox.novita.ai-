import '../models/emotion.dart';

/// "몽이의 주간 편지" - 이미 있는 [EmotionInsightService.buildWeeklyReport]가
/// 숫자/그래프로 이번 주를 보여주는 것과 달리, 같은 최근 7일 데이터를
/// 몽이가 직접 쓴 것 같은 다정한 손편지 문단들로 바꿔서 들려준다.
///
/// 서버/AI 없이 로컬 데이터 + 룰 기반 템플릿만으로 동작하며, 어떤 함수도
/// 위젯/상태를 건드리지 않고 값만 계산해서 반환한다(테스트 용이, 부작용 없음)
/// - [EmotionInsightService], [MongiMoodService]와 동일한 설계 원칙을 따른다.
///
/// 실제 문구는 화면에서 [AppLocalizations]를 통해 언어별로 골라 붙인다 -
/// 이 서비스는 [MongiLetterBodyResult]/[MongiLetterStreakResult] 같은
/// 언어 중립적인 값만 계산해서 반환한다.
class MongiLetterService {
  const MongiLetterService._();

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// 최근 7일(오늘 포함) 안의 일기 항목만 골라낸다.
  static List<Map<String, dynamic>> _entriesInLast7Days(
    List<Map<String, dynamic>> diaryEntries,
  ) {
    final cutoff = _today.subtract(const Duration(days: 6));
    return diaryEntries.where((entry) {
      final date = _parseDate(entry['date'] as String?);
      return date != null && !date.isBefore(cutoff);
    }).toList();
  }

  /// 이번 주 편지를 만든다. 데이터가 너무 적으면(3회 미만)
  /// [MongiWeeklyLetter.hasEnoughData]가 false로 반환된다(화면에서 대신
  /// 안내 문구를 보여준다).
  static MongiWeeklyLetter buildWeeklyLetter({
    required List<Map<String, dynamic>> diaryEntries,
    required int checkInStreak,
  }) {
    final entries = _entriesInLast7Days(diaryEntries);
    if (entries.length < 3) {
      return const MongiWeeklyLetter(hasEnoughData: false);
    }

    final emotionCounts = <String, int>{};
    final targetCounts = <String, int>{};
    var positiveCount = 0;
    var notedCount = 0;
    for (final entry in entries) {
      final typeName = entry['emotionType'] as String?;
      if (typeName != null) {
        emotionCounts[typeName] = (emotionCounts[typeName] ?? 0) + 1;
        if (Emotion.byTypeName(typeName).isPositive) {
          positiveCount++;
        }
      }
      final target = entry['targetName'] as String?;
      if (target != null && target.trim().isNotEmpty) {
        final trimmed = target.trim();
        targetCounts[trimmed] = (targetCounts[trimmed] ?? 0) + 1;
      }
      final note = entry['note'] as String?;
      if (note != null && note.trim().isNotEmpty) notedCount++;
    }

    final total = entries.length;
    final positiveRatio = total == 0 ? 0.0 : positiveCount / total;
    final noteRatio = total == 0 ? 0.0 : notedCount / total;

    Emotion? topEmotion;
    var topEmotionRatio = 0.0;
    if (emotionCounts.isNotEmpty) {
      final sorted = emotionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topEmotion = Emotion.byTypeName(sorted.first.key);
      topEmotionRatio = sorted.first.value / total;
    }

    String? topTarget;
    var topTargetCount = 0;
    if (targetCounts.isNotEmpty) {
      final sorted = targetCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topTarget = sorted.first.key;
      topTargetCount = sorted.first.value;
    }

    return MongiWeeklyLetter(
      hasEnoughData: true,
      bodyResult: _buildBodyResult(
        topTarget: topTarget,
        topTargetCount: topTargetCount,
        topEmotion: topEmotion,
        topEmotionRatio: topEmotionRatio,
        noteRatio: noteRatio,
        positiveRatio: positiveRatio,
        total: total,
      ),
      streakResult: _buildStreakResult(checkInStreak),
    );
  }

  /// 편지의 본문 문단 - 이번 주 데이터 중 가장 눈에 띄는 것 하나를 골라
  /// 그 이야기를 들려준다(여러 조건이 겹치면 우선순위대로 하나만 고른다).
  static MongiLetterBodyResult _buildBodyResult({
    required String? topTarget,
    required int topTargetCount,
    required Emotion? topEmotion,
    required double topEmotionRatio,
    required double noteRatio,
    required double positiveRatio,
    required int total,
  }) {
    // 1순위: 특정 대상(사람/일)이 반복해서 언급됐을 때 - 가장 구체적인 이야기.
    if (topTarget != null && topTargetCount >= 2) {
      return MongiLetterBodyResult(
        kind: MongiLetterBodyKind.topTarget,
        target: topTarget,
      );
    }

    // 2순위: 특정 감정이 압도적으로 많았을 때.
    if (topEmotion != null && topEmotionRatio >= 0.5 && total >= 3) {
      return MongiLetterBodyResult(
        kind: MongiLetterBodyKind.topEmotion,
        emotion: topEmotion,
      );
    }

    // 3순위: 이야기(메모)를 많이 남긴 주 - 기록 자체를 인정.
    if (noteRatio >= 0.5) {
      return const MongiLetterBodyResult(kind: MongiLetterBodyKind.manyNotes);
    }

    // 4순위: 긍정 비율이 높은 주 - 함께 기뻐하기.
    if (positiveRatio >= 0.6) {
      return const MongiLetterBodyResult(
        kind: MongiLetterBodyKind.mostlyPositive,
      );
    }

    // 5순위: 부정 비율이 높은 주 - 다그치지 않고 곁을 지켰다는 것만 전한다.
    if (positiveRatio <= 0.3) {
      return const MongiLetterBodyResult(kind: MongiLetterBodyKind.mostlyHeavy);
    }

    // 기본값: 특별히 도드라지는 게 없어도 함께한 한 주 자체를 담담하게 전한다.
    return const MongiLetterBodyResult(kind: MongiLetterBodyKind.defaultThanks);
  }

  /// 체크인 연속일에 따른 마무리 격려 문단.
  static MongiLetterStreakResult _buildStreakResult(int checkInStreak) {
    if (checkInStreak >= 7) {
      return MongiLetterStreakResult(
        kind: MongiLetterStreakKind.longStreak,
        streak: checkInStreak,
      );
    }
    if (checkInStreak >= 3) {
      return MongiLetterStreakResult(
        kind: MongiLetterStreakKind.shortStreak,
        streak: checkInStreak,
      );
    }
    return MongiLetterStreakResult(
      kind: MongiLetterStreakKind.noStreak,
      streak: checkInStreak,
    );
  }
}

/// [MongiLetterService.buildWeeklyLetter]가 고를 수 있는 본문 문단 종류.
/// 실제 문구는 화면에서 [AppLocalizations]를 통해 언어별로 골라 붙인다.
enum MongiLetterBodyKind {
  topTarget,
  topEmotion,
  manyNotes,
  mostlyPositive,
  mostlyHeavy,
  defaultThanks,
}

/// [MongiLetterService._buildBodyResult]의 계산 결과.
class MongiLetterBodyResult {
  final MongiLetterBodyKind kind;

  /// topTarget에서 쓰이는 "이번 주 가장 많이 언급된 대상".
  final String? target;

  /// topEmotion에서 쓰이는 "이번 주 가장 많이 만난 감정".
  final Emotion? emotion;

  const MongiLetterBodyResult({required this.kind, this.target, this.emotion});
}

/// [MongiLetterService.buildWeeklyLetter]가 고를 수 있는 마무리 격려 문단 종류.
enum MongiLetterStreakKind { longStreak, shortStreak, noStreak }

/// [MongiLetterService._buildStreakResult]의 계산 결과.
class MongiLetterStreakResult {
  final MongiLetterStreakKind kind;

  /// longStreak/shortStreak/noStreak 문구에 끼워 넣는 연속 체크인 일수.
  final int streak;

  const MongiLetterStreakResult({required this.kind, required this.streak});
}

/// [MongiLetterService.buildWeeklyLetter]의 계산 결과.
class MongiWeeklyLetter {
  /// 편지를 쓸 만큼 데이터가 충분히 쌓였는지(최소 3회 이상).
  final bool hasEnoughData;

  /// [hasEnoughData]가 true일 때만 채워지는 본문 문단 결과.
  final MongiLetterBodyResult? bodyResult;

  /// [hasEnoughData]가 true일 때만 채워지는 마무리 격려 문단 결과.
  final MongiLetterStreakResult? streakResult;

  const MongiWeeklyLetter({
    required this.hasEnoughData,
    this.bodyResult,
    this.streakResult,
  });
}
