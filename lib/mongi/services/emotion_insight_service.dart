import '../models/emotion.dart';
import '../models/emotion_trigger.dart';

/// 이미 저장된 [GardenProvider.diaryEntries](최신순, 최대 200개, 항목당
/// {date, emotionType, targetName, eatenCount, note})만으로 "감정 데이터를
/// 사용자에게 되돌려주는" 여러 인사이트를 계산하는 순수 함수 모음.
///
/// 서버/AI 없이 로컬 데이터 + 룰 기반 템플릿만으로 동작하도록 설계했다.
/// 어떤 함수도 위젯/상태를 건드리지 않고 값만 계산해서 반환한다(테스트 용이,
/// 부작용 없음).
class EmotionInsightService {
  const EmotionInsightService._();

  /// "이번 주"로 볼 기간(오늘 포함 며칠).
  static const int defaultWindowDays = 7;

  /// "yyyy-M-d" 형식(GardenStorage._todayString과 동일한 포맷)의 문자열을
  /// DateTime으로 안전하게 파싱한다. 형식이 어긋나면 null.
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

  /// 오늘 날짜(시:분:초 제거).
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 최근 [days]일(오늘 포함) 안에 [emotionType]을 몇 번 일기에 남겼는지.
  static int countRecentOccurrences({
    required List<Map<String, dynamic>> diaryEntries,
    required EmotionType emotionType,
    int days = defaultWindowDays,
  }) {
    final cutoff = _today.subtract(Duration(days: days - 1));
    var count = 0;
    for (final entry in diaryEntries) {
      if (entry['emotionType'] != emotionType.name) continue;
      final date = _parseDate(entry['date'] as String?);
      if (date == null) continue;
      if (!date.isBefore(cutoff)) count++;
    }
    return count;
  }

  /// 이 감정을 마지막으로 만난 지 며칠이 지났는지. 기록이 아예 없으면 null.
  static int? daysSinceLastOccurrence({
    required List<Map<String, dynamic>> diaryEntries,
    required EmotionType emotionType,
  }) {
    DateTime? latest;
    for (final entry in diaryEntries) {
      if (entry['emotionType'] != emotionType.name) continue;
      final date = _parseDate(entry['date'] as String?);
      if (date == null) continue;
      if (latest == null || date.isAfter(latest)) latest = date;
    }
    if (latest == null) return null;
    return _today.difference(latest).inDays;
  }

  /// 방금 끝난 세션에 대해 결과 화면에서 보여줄 "즉시 피드백" 한 줄을 만든다.
  ///
  /// 주의: 이 세션은 호출 시점에 아직 [diaryEntries]에 저장되지 않은 상태다
  /// (실제 저장은 사용자가 "처음으로"를 눌러 홈으로 돌아갈 때 이뤄진다).
  /// 그래서 "이번 주 횟수"를 셀 때 과거 기록 + 이번 세션(1)을 더해서 판단한다.
  ///
  /// 매번 뭔가 보여주면 오히려 소음이 되므로, 아래 우선순위 중 하나에도
  /// 해당하지 않으면 null을 반환해서 문구를 아예 생략한다.
  ///
  /// 고정 한국어 문자열 대신 "종류 + 필요한 값"만 계산해서 돌려준다.
  /// 다국어 지원을 위한 버전으로, [MongiMoodService]와 동일한 설계
  /// 원칙("문구는 화면에서 AppLocalizations로 완성한다")을 따른다.
  static SessionInsightResult? buildSessionInsightKind({
    required List<Map<String, dynamic>> diaryEntries,
    required Emotion primaryEmotion,
    required List<Emotion> selectedEmotions,
  }) {
    final pastWeekCount = countRecentOccurrences(
      diaryEntries: diaryEntries,
      emotionType: primaryEmotion.type,
    );
    final thisWeekCount = pastWeekCount + 1; // +1 = 이번 세션
    final daysSince = daysSinceLastOccurrence(
      diaryEntries: diaryEntries,
      emotionType: primaryEmotion.type,
    );

    if (thisWeekCount >= 3) {
      return SessionInsightResult(
        kind: primaryEmotion.isPositive
            ? SessionInsightKind.frequentPositive
            : SessionInsightKind.frequentNegative,
        count: thisWeekCount,
      );
    }

    if (selectedEmotions.isNotEmpty &&
        selectedEmotions.every((e) => e.isPositive)) {
      return const SessionInsightResult(kind: SessionInsightKind.allPositive);
    }

    if (daysSince != null && daysSince >= 10) {
      return SessionInsightResult(
        kind: SessionInsightKind.longAbsence,
        emotion: primaryEmotion,
        days: daysSince,
      );
    }

    if (pastWeekCount == 0 && daysSince == null) {
      return SessionInsightResult(
        kind: SessionInsightKind.firstEncounter,
        emotion: primaryEmotion,
      );
    }

    return null;
  }

  /// "마음 돌봄" 관련 안내를 조심스럽게 권해도 좋을 시점인지 판단한다.
  ///
  /// 절대 진단이나 판정을 하지 않는다 - 이 함수는 오직 "최근 2주간 무거운
  /// 마음이 유독 꾸준히, 자주 기록되었는지"만 아주 보수적인 기준으로
  /// 살펴보고, 해당할 때만 조용히 "필요하면 도움받을 곳이 있다"는 사실을
  /// 알려주기 위한 신호로 쓰인다. 이 신호가 꺼져 있어도 [MentalHealthSupportScreen]은
  /// 설정 화면 등에서 언제나 접근 가능해야 한다.
  static bool shouldSuggestSupport({
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    final entries = _entriesInWindow(
      diaryEntries: diaryEntries,
      startDaysAgo: 14,
      endDaysAgo: 1,
    );
    // 표본이 너무 적으면(우연일 가능성이 큼) 판단하지 않는다.
    if (entries.length < 6) return false;

    var negativeCount = 0;
    var heavyCount = 0;
    for (final entry in entries) {
      final typeName = entry['emotionType'] as String?;
      if (typeName == null) continue;
      final emotion = Emotion.byTypeName(typeName);
      if (emotion.isPositive) continue;
      negativeCount++;
      if (_heavySignalTypes.contains(emotion.type)) heavyCount++;
    }

    final negativeRatio = negativeCount / entries.length;
    // 부정 감정이 절대다수(75% 이상)이면서, 그중에서도 슬픔/외로움/두려움/
    // 불안처럼 유독 무거운 감정이 반복적으로(4회 이상) 나타났을 때만 표시.
    return negativeRatio >= 0.75 && heavyCount >= 4;
  }

  /// [shouldSuggestSupport]에서 "무거운 마음"으로 보는 감정 타입.
  /// 화·짜증·부끄러움처럼 비교적 일시적인 감정은 제외하고, 지속되면
  /// 마음을 더 크게 짓누를 수 있는 감정 위주로 신중하게 골랐다.
  static const Set<EmotionType> _heavySignalTypes = {
    EmotionType.sadness,
    EmotionType.loneliness,
    EmotionType.fear,
    EmotionType.anxiety,
    EmotionType.hate,
    EmotionType.grievance,
  };

  /// 지금까지 쌓인 일기 중 가장 자주 마주한 감정 상위 [limit]개.
  /// (감정, 등장 횟수) 쌍을 등장 횟수 내림차순으로 반환한다.
  static List<MapEntry<Emotion, int>> topEmotions({
    required List<Map<String, dynamic>> diaryEntries,
    int limit = 3,
  }) {
    final counts = <String, int>{};
    for (final entry in diaryEntries) {
      final typeName = entry['emotionType'] as String?;
      if (typeName == null) continue;
      counts[typeName] = (counts[typeName] ?? 0) + 1;
    }
    final list =
        counts.entries
            .map((e) => MapEntry(Emotion.byTypeName(e.key), e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  /// "가장 크게 성장한 마음" - 일기 타임라인을 오래된 순으로 반으로 나눠서,
  /// 앞 절반보다 뒤 절반에서 등장 횟수가 가장 많이 줄어든 감정을 찾는다.
  /// (부정 감정이 줄었다는 건 그만큼 마음이 편해졌다는 신호로 볼 수 있다)
  ///
  /// 데이터가 너무 적거나(4개 미만) 뚜렷하게 줄어든 감정이 없으면 null.
  static Emotion? mostImprovedEmotion({
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    if (diaryEntries.length < 4) return null;
    // diaryEntries는 최신순 저장이므로, 오래된 순으로 뒤집는다.
    final chronological = diaryEntries.reversed.toList();
    final mid = chronological.length ~/ 2;
    final olderHalf = chronological.sublist(0, mid);
    final newerHalf = chronological.sublist(mid);

    int countIn(List<Map<String, dynamic>> half, String typeName) =>
        half.where((e) => e['emotionType'] == typeName).length;

    Emotion? best;
    var bestDrop = 0;
    for (final emotion in Emotion.all) {
      if (!emotion.isPositive) {
        // 부정 감정만 대상으로: 줄어든 것이 "성장"의 신호이기 때문.
        final olderCount = countIn(olderHalf, emotion.type.name);
        final newerCount = countIn(newerHalf, emotion.type.name);
        final drop = olderCount - newerCount;
        // 최소 2번 이상 등장했던 감정이어야 의미 있는 비교(우연 배제).
        if (olderCount >= 2 && drop > bestDrop) {
          bestDrop = drop;
          best = emotion;
        }
      }
    }
    return best;
  }

  /// 10번: 이 감정 타입에 대해 유저가 실제로 남긴 가장 최근 다이어리 한 줄
  /// (note)을 찾는다. 게임 중 "냠!" 같은 정형화된 문구 대신, 그때 그 순간
  /// 스스로 적어뒀던 말을 몽이가 다시 들려주는 순간을 만들기 위함이다.
  /// [diaryEntries]는 최신순 저장이므로 배열을 앞에서부터 훑다가, note가
  /// null/공백이 아닌 첫 기록(=이 감정 타입으로 실제로 뭔가를 적어둔 가장
  /// 최신 기록)을 찾으면 그 즉시 반환한다. 하나도 없으면 null.
  static String? mostRecentNoteFor({
    required List<Map<String, dynamic>> diaryEntries,
    required EmotionType emotionType,
  }) {
    for (final entry in diaryEntries) {
      if (entry['emotionType'] != emotionType.name) continue;
      final note = entry['note'] as String?;
      if (note != null && note.trim().isNotEmpty) return note.trim();
    }
    return null;
  }

  /// 게임 컷인 카드(고정 크기, 자동 줄바꿈 없음)에 안전하게 들어가도록 너무
  /// 긴 노트를 잘라낸다. [Emotion.healMessage]의 기존 문구들이 한 줄당
  /// 대략 12~16자 안팎인 것과 비슷한 길이로 맞추기 위해, 기본값을 짧게
  /// (10자) 잡는다 - 카드에는 이 노트 앞뒤로 인용부호만 붙으므로, 두 줄
  /// 문구 전체가 기존 healMessage와 비슷한 폭 안에 들어온다.
  static String _truncateForCutIn(String note, {int maxLength = 10}) {
    if (note.length <= maxLength) return note;
    return '${note.substring(0, maxLength)}…';
  }

  /// 10번: 게임 플레이 중 같은 감정을 연속으로 먹었을 때(스트릭 컷인) 보여줄
  /// 수 있는, 실제 다이어리 기록과 연결된 힐링 문구. "냠! OO 사라졌어요"
  /// 같은 정형화된 반응 대신, 유저가 예전에 스스로 남긴 한 줄을 몽이가
  /// 다시 들려준다 - "이 앱이 내 이야기를 정말 기억하고 있다"는 인상을
  /// 주기 위함이다. 이 감정 타입으로 남긴 노트가 하나도 없으면 null을
  /// 반환하므로, 호출부는 반드시 null 처리(기존 healMessage로 대체)를
  /// 해야 한다.
  static String? diaryLinkedCutInMessage({
    required Emotion emotion,
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    final note = mostRecentNoteFor(
      diaryEntries: diaryEntries,
      emotionType: emotion.type,
    );
    if (note == null) return null;
    final shortNote = _truncateForCutIn(note);
    return '"$shortNote"\n그 마음, 몽이가 기억하고 있어요 🤍';
  }

  /// 아직 일기에 한 번도 등장하지 않은 감정의 개수(전체 15종 기준).
  static int uncollectedEmotionCount({
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    final encountered = diaryEntries
        .map((e) => e['emotionType'] as String?)
        .whereType<String>()
        .toSet();
    return Emotion.all.length - encountered.length;
  }

  /// 오늘부터 [days]일 전(포함)까지의 일기 항목만 걸러낸다.
  static List<Map<String, dynamic>> _entriesInWindow({
    required List<Map<String, dynamic>> diaryEntries,
    required int startDaysAgo,
    required int endDaysAgo,
  }) {
    final start = _today.subtract(Duration(days: startDaysAgo - 1));
    final end = _today.subtract(Duration(days: endDaysAgo));
    return diaryEntries.where((entry) {
      final date = _parseDate(entry['date'] as String?);
      if (date == null) return false;
      return !date.isBefore(end) && !date.isAfter(start);
    }).toList();
  }

  /// [days]일 창(오늘 포함) 안에 남긴 일기 항목 총 개수.
  static int totalSessionsInWindow({
    required List<Map<String, dynamic>> diaryEntries,
    int days = defaultWindowDays,
  }) {
    return _entriesInWindow(
      diaryEntries: diaryEntries,
      startDaysAgo: days,
      endDaysAgo: 1,
    ).length;
  }

  /// 매주 반복되는 대신 한 번만 계산해서 화면에 그대로 넘겨주는 "주간 감정 리포트".
  static WeeklyEmotionReport buildWeeklyReport({
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    final thisWeek = _entriesInWindow(
      diaryEntries: diaryEntries,
      startDaysAgo: 7,
      endDaysAgo: 1,
    );
    final lastWeek = _entriesInWindow(
      diaryEntries: diaryEntries,
      startDaysAgo: 14,
      endDaysAgo: 8,
    );

    final counts = <String, int>{};
    var totalEaten = 0;
    var positiveCount = 0;
    var negativeCount = 0;
    var notedCount = 0;
    for (final entry in thisWeek) {
      final typeName = entry['emotionType'] as String?;
      if (typeName == null) continue;
      counts[typeName] = (counts[typeName] ?? 0) + 1;
      totalEaten += (entry['eatenCount'] as num?)?.toInt() ?? 0;
      final note = entry['note'] as String?;
      if (note != null && note.trim().isNotEmpty) notedCount++;
      final emotion = Emotion.byTypeName(typeName);
      if (emotion.isPositive) {
        positiveCount++;
      } else {
        negativeCount++;
      }
    }

    var lastWeekPositive = 0;
    for (final entry in lastWeek) {
      final typeName = entry['emotionType'] as String?;
      if (typeName == null) continue;
      if (Emotion.byTypeName(typeName).isPositive) lastWeekPositive++;
    }

    final emotionCounts =
        counts.entries
            .map((e) => MapEntry(Emotion.byTypeName(e.key), e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final totalThisWeek = thisWeek.length;
    final positiveRatio = totalThisWeek == 0
        ? 0.0
        : positiveCount / totalThisWeek;
    final previousPositiveRatio = lastWeek.isEmpty
        ? null
        : lastWeekPositive / lastWeek.length;
    final noteRatio = totalThisWeek == 0 ? 0.0 : notedCount / totalThisWeek;

    return WeeklyEmotionReport(
      totalSessions: totalThisWeek,
      totalEaten: totalEaten,
      emotionCounts: emotionCounts,
      positiveCount: positiveCount,
      negativeCount: negativeCount,
      positiveRatio: positiveRatio,
      previousPositiveRatio: previousPositiveRatio,
      observationResult: _buildWeeklyObservationResult(
        emotionCounts: emotionCounts,
        totalThisWeek: totalThisWeek,
        positiveRatio: positiveRatio,
        previousPositiveRatio: previousPositiveRatio,
        noteRatio: noteRatio,
      ),
    );
  }

  /// 주간 리포트에 표시할 한 줄 관찰 문구 계산 - "판단"이 아니라 "관찰"에
  /// 머무르도록 톤을 유지하고, 부정 감정이 많은 주에도 다그치지 않는다.
  /// 언어 중립적인 종류/값만 계산해서 돌려주며, 화면에서
  /// [AppLocalizations]로 언어별 문구를 고를 때 사용한다.
  static WeeklyObservationResult _buildWeeklyObservationResult({
    required List<MapEntry<Emotion, int>> emotionCounts,
    required int totalThisWeek,
    required double positiveRatio,
    required double? previousPositiveRatio,
    required double noteRatio,
  }) {
    if (totalThisWeek == 0) {
      return const WeeklyObservationResult(kind: WeeklyObservationKind.noData);
    }

    if (previousPositiveRatio != null &&
        positiveRatio - previousPositiveRatio >= 0.15) {
      final deltaPercent = ((positiveRatio - previousPositiveRatio) * 100)
          .round();
      return WeeklyObservationResult(
        kind: WeeklyObservationKind.improvedFromLastWeek,
        deltaPercent: deltaPercent,
      );
    }

    if (previousPositiveRatio != null &&
        previousPositiveRatio - positiveRatio >= 0.2 &&
        totalThisWeek >= 3) {
      return const WeeklyObservationResult(
        kind: WeeklyObservationKind.declinedFromLastWeek,
      );
    }

    if (emotionCounts.isNotEmpty) {
      final top = emotionCounts.first;
      final topRatio = top.value / totalThisWeek;
      if (topRatio >= 0.7 && totalThisWeek >= 3) {
        return WeeklyObservationResult(
          kind: top.key.isPositive
              ? WeeklyObservationKind.dominantPositive
              : WeeklyObservationKind.dominantNegative,
          emotion: top.key,
        );
      }
    }

    if (noteRatio >= 0.5 && totalThisWeek >= 3) {
      return const WeeklyObservationResult(
        kind: WeeklyObservationKind.manyNotes,
      );
    }

    if (positiveRatio <= 0.25 && totalThisWeek >= 3) {
      return const WeeklyObservationResult(
        kind: WeeklyObservationKind.mostlyHeavy,
      );
    }

    if (emotionCounts.isNotEmpty) {
      final top = emotionCounts.first;
      return WeeklyObservationResult(
        kind: WeeklyObservationKind.defaultTopEmotion,
        emotion: top.key,
        count: top.value,
      );
    }
    return const WeeklyObservationResult(
      kind: WeeklyObservationKind.defaultThanks,
    );
  }

  /// 홈 화면 상단 배지에 넣을 아주 짧은(한 줄) "오늘의 목표" 문구.
  /// [buildNextGoalHintKind]/[buildPersonalizedReminder]와 우선순위 후보는
  /// 같은 데이터를 쓰지만, 배지는 공간이 좁으므로 훨씬 짧게 압축한다.
  static String? buildTodayGoalBadge({
    required List<Map<String, dynamic>> diaryEntries,
    required int pointsToNextTreeStage,
  }) {
    final uncollected = uncollectedEmotionCount(diaryEntries: diaryEntries);

    if (uncollected > 0 && uncollected <= 3) {
      return '도감 $uncollected개 남음';
    }
    if (pointsToNextTreeStage > 0 && pointsToNextTreeStage <= 30) {
      return '나무까지 $pointsToNextTreeStage점';
    }
    if (uncollected > 0) {
      return '미수집 마음 $uncollected가지';
    }
    return null;
  }

  /// 매일 알림에 넣을 "지금 이 유저에게 가장 의미 있는" 한 줄을 고른다.
  /// 결과 화면용 [buildNextGoalHintKind]와 후보는 비슷하지만, 알림은 "오늘 안
  /// 오면 아쉬운 것"을 우선한다 - 특히 스트릭이 끊기기 직전이라는 긴장감이
  /// 앱 밖에 있는 유저를 돌아오게 만드는 가장 강한 신호이기 때문이다.
  ///
  /// 해당하는 후보가 없으면 null을 반환하고, 이때는 호출부에서 기존 고정
  /// 문구 중 하나를 랜덤으로 대신 쓰면 된다.
  static String? buildPersonalizedReminder({
    required List<Map<String, dynamic>> diaryEntries,
    required int streakDays,
    required int pointsToNextTreeStage,
  }) {
    final uncollected = uncollectedEmotionCount(diaryEntries: diaryEntries);

    // 1순위: 연속 기록(스트릭)이 3일 이상 쌓였을 때 - 오늘 놓치면 끊긴다는
    // 아쉬움을 다그치지 않는 톤으로 짚어준다.
    if (streakDays >= 3) {
      return '지금 $streakDays일째 몽이와 함께하고 있어요!\n오늘도 이어가볼까요? 🔥';
    }

    // 2순위: 감정 도감이 거의 다 채워졌을 때.
    if (uncollected > 0 && uncollected <= 3) {
      return '이제 $uncollected가지 마음만 더 만나면\n도감이 완성돼요 🔍';
    }

    // 3순위: 몽이의 성장나무가 다음 단계까지 얼마 남지 않았을 때.
    if (pointsToNextTreeStage > 0 && pointsToNextTreeStage <= 30) {
      return '몽이의 나무가 다음 단계까지\n조금밖에 안 남았어요 🌳';
    }

    return null;
  }

  /// 결과 화면에서 "다음에도 오고 싶어지는" 이유를 하나 짚어주는 한 줄 문구.
  /// 매 판이 완벽하게 "끝"나버리면 재방문 욕구가 생기기 어렵다는 진단에서
  /// 나온 함수 - 자이가르닉 효과(완결된 것보다 미완성으로 남은 것에 더 끌리는
  /// 심리)를 활용해, 이번 판 이후에도 "아직 안 끝난 무언가"를 살짝 보여준다.
  ///
  /// 여러 후보 중 가장 의미 있는 것 하나만 우선순위로 골라서 보여주고(소음
  /// 방지), 보여줄 만한 게 없으면 null을 반환해 문구 자체를 생략한다.
  ///
  /// 고정 한국어 문자열 대신 "종류 + 필요한 값"만 계산해서 돌려준다.
  /// 다국어 지원을 위한 버전이다.
  static NextGoalHintResult? buildNextGoalHintKind({
    required List<Map<String, dynamic>> diaryEntries,
    required int pointsToNextTreeStage,
  }) {
    final uncollected = uncollectedEmotionCount(diaryEntries: diaryEntries);

    if (uncollected > 0 && uncollected <= 3) {
      return NextGoalHintResult(
        kind: NextGoalHintKind.almostCollected,
        count: uncollected,
      );
    }

    if (pointsToNextTreeStage > 0 && pointsToNextTreeStage <= 30) {
      return NextGoalHintResult(
        kind: NextGoalHintKind.treeAlmost,
        count: pointsToNextTreeStage,
      );
    }

    if (uncollected > 0) {
      return NextGoalHintResult(
        kind: NextGoalHintKind.manyUncollected,
        count: uncollected,
      );
    }

    return null;
  }

  /// 며칠 못 왔다가 다시 돌아왔을 때(=스트릭이 끊긴 뒤) 보여줄 "복귀 케어"
  /// 문구의 종류를 계산한다. [daysSinceLastFeed]는 [GardenStorage]/
  /// [GardenProvider]에 이미 있던 값을 그대로 재사용하며(새 저장 스키마
  /// 불필요), 오늘 한 번이라도 정원에 감정을 먹이면(recordSession 호출) 곧바로
  /// 0으로 돌아가 이 카드도 자연스럽게 사라진다 - 별도의 "봤음" 플래그를
  /// 저장하지 않는 이유다.
  ///
  /// 이틀 이내(하루쯔음 거른 것)는 흔한 일이라 굳이 언급하지 않고(다그치지
  /// 않는 톤 유지), 이틀 이상 안 왔을 때만 "다시 만나서 반갑다"는 가벼운
  /// 환영 문구를 보여준다. 일주일 이상 비었을 때는 톤을 조금 더 다정하게
  /// 낮춰서, 오래 쉬었다 온 것에 부담을 느끼지 않도록 한다.
  static ComebackCareResult? buildComebackCareKind({
    required int daysSinceLastFeed,
  }) {
    if (daysSinceLastFeed >= 7) {
      return ComebackCareResult(
        kind: ComebackCareKind.longBreak,
        days: daysSinceLastFeed,
      );
    }
    if (daysSinceLastFeed >= 2) {
      return ComebackCareResult(
        kind: ComebackCareKind.shortBreak,
        days: daysSinceLastFeed,
      );
    }
    return null;
  }

  /// [month]가 속한 달(1일 ~ 말일)의 일기 항목만 걸러낸다. 반환값은
  /// (날짜, 항목) 쌍 형태가 아니라 그대로 [Map] 목록이며, 정렬 순서는
  /// 원본([diaryEntries], 최신순)을 그대로 따른다.
  static List<Map<String, dynamic>> _entriesInMonth({
    required List<Map<String, dynamic>> diaryEntries,
    required DateTime month,
  }) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    return diaryEntries.where((entry) {
      final date = _parseDate(entry['date'] as String?);
      if (date == null) return false;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();
  }

  /// 특정 달에 대해 "이달의 감정 키워드 / 감정 다양성 지수 / 최장 연속 기록 /
  /// 주차별 긍정-부정 추이 / 감정 분포(비율) / 전월 대비 가벼운 분석"을 한 번에
  /// 계산한다. 감정 캘린더 화면의 해석 패널에서 사용한다.
  static MonthlyEmotionInsight buildMonthlyInsight({
    required List<Map<String, dynamic>> diaryEntries,
    required DateTime month,
  }) {
    final monthEntries = _entriesInMonth(
      diaryEntries: diaryEntries,
      month: month,
    );

    // 1) 감정별 등장 횟수 + 고유 감정 종류 수.
    final counts = <String, int>{};
    var positiveCount = 0;
    var negativeCount = 0;
    for (final entry in monthEntries) {
      final typeName = entry['emotionType'] as String?;
      if (typeName == null) continue;
      counts[typeName] = (counts[typeName] ?? 0) + 1;
      if (Emotion.byTypeName(typeName).isPositive) {
        positiveCount++;
      } else {
        negativeCount++;
      }
    }
    final emotionCounts =
        counts.entries
            .map((e) => MapEntry(Emotion.byTypeName(e.key), e.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // 2) 이 달에 실제로 기록이 있었던 날짜(중복 제거, 오름차순 정렬)로
    //    최장 연속 기록일(스트릭)을 계산한다.
    final uniqueDates =
        monthEntries
            .map((e) => _parseDate(e['date'] as String?))
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort();
    var longestStreak = 0;
    var currentStreak = 0;
    DateTime? prevDate;
    for (final date in uniqueDates) {
      if (prevDate != null && date.difference(prevDate).inDays == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > longestStreak) longestStreak = currentStreak;
      prevDate = date;
    }

    // 3) 주차별(달의 1일 기준 7일 단위) 긍정 비율 & 총 기록 수.
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weekCount = ((daysInMonth - 1) ~/ 7) + 1; // 최대 5주차
    final weeklyPositive = List<int>.filled(weekCount, 0);
    final weeklyTotal = List<int>.filled(weekCount, 0);
    for (final entry in monthEntries) {
      final date = _parseDate(entry['date'] as String?);
      final typeName = entry['emotionType'] as String?;
      if (date == null || typeName == null) continue;
      final weekIndex = ((date.day - 1) ~/ 7).clamp(0, weekCount - 1);
      weeklyTotal[weekIndex]++;
      if (Emotion.byTypeName(typeName).isPositive) {
        weeklyPositive[weekIndex]++;
      }
    }
    final weeklyPositiveRatios = List<double?>.generate(weekCount, (i) {
      if (weeklyTotal[i] == 0) return null;
      return weeklyPositive[i] / weeklyTotal[i];
    });

    // 4) 전월 대비 비교("가벼운 분석"의 재료) - 전월 기록의 긍정 비율만
    //    필요한 만큼만 가볍게 계산한다(주간 리포트의 previousPositiveRatio와
    //    동일한 방식).
    final previousMonth = DateTime(month.year, month.month - 1, 1);
    final previousMonthEntries = _entriesInMonth(
      diaryEntries: diaryEntries,
      month: previousMonth,
    );
    double? previousPositiveRatio;
    if (previousMonthEntries.isNotEmpty) {
      var prevPositive = 0;
      for (final entry in previousMonthEntries) {
        final typeName = entry['emotionType'] as String?;
        if (typeName == null) continue;
        if (Emotion.byTypeName(typeName).isPositive) prevPositive++;
      }
      previousPositiveRatio = prevPositive / previousMonthEntries.length;
    }

    final totalThisMonth = monthEntries.length;
    final positiveRatio = totalThisMonth == 0
        ? 0.0
        : positiveCount / totalThisMonth;

    return MonthlyEmotionInsight(
      totalSessions: totalThisMonth,
      emotionCounts: emotionCounts,
      uniqueEmotionCount: counts.length,
      longestStreak: longestStreak,
      weeklyPositiveRatios: weeklyPositiveRatios,
      weeklySessionCounts: weeklyTotal,
      positiveCount: positiveCount,
      negativeCount: negativeCount,
      positiveRatio: positiveRatio,
      previousPositiveRatio: previousPositiveRatio,
      observationResult: _buildMonthlyObservationResult(
        emotionCounts: emotionCounts,
        totalThisMonth: totalThisMonth,
        positiveRatio: positiveRatio,
        previousPositiveRatio: previousPositiveRatio,
        uniqueEmotionCount: counts.length,
      ),
    );
  }

  /// 월간 캘린더 해석 패널에 넣을 한 줄 "가벼운 분석" 문구를 계산한다.
  /// [_buildWeeklyObservationResult]와 같은 우선순위 기반 판정 구조를
  /// 그대로 따르되, 기준값은 "한 달" 단위 표본에 맞게 다시 조정했다 -
  /// 표본이 더 크게 쌓이는 만큼(최소 3회는 동일하게 유지) 판단은 여전히
  /// "관찰"에 머무르고, 다그치거나 진단하지 않는 톤을 지킨다.
  static MonthlyObservationResult _buildMonthlyObservationResult({
    required List<MapEntry<Emotion, int>> emotionCounts,
    required int totalThisMonth,
    required double positiveRatio,
    required double? previousPositiveRatio,
    required int uniqueEmotionCount,
  }) {
    if (totalThisMonth < 3) {
      return const MonthlyObservationResult(
        kind: MonthlyObservationKind.noData,
      );
    }

    if (previousPositiveRatio != null &&
        positiveRatio - previousPositiveRatio >= 0.15) {
      final deltaPercent = ((positiveRatio - previousPositiveRatio) * 100)
          .round();
      return MonthlyObservationResult(
        kind: MonthlyObservationKind.improvedFromLastMonth,
        deltaPercent: deltaPercent,
      );
    }

    if (previousPositiveRatio != null &&
        previousPositiveRatio - positiveRatio >= 0.2) {
      return const MonthlyObservationResult(
        kind: MonthlyObservationKind.declinedFromLastMonth,
      );
    }

    if (emotionCounts.isNotEmpty) {
      final top = emotionCounts.first;
      final topRatio = top.value / totalThisMonth;
      if (topRatio >= 0.6) {
        return MonthlyObservationResult(
          kind: top.key.isPositive
              ? MonthlyObservationKind.dominantPositive
              : MonthlyObservationKind.dominantNegative,
          emotion: top.key,
          percent: (topRatio * 100).round(),
        );
      }
    }

    if (uniqueEmotionCount >= 8) {
      return MonthlyObservationResult(
        kind: MonthlyObservationKind.diverseEmotions,
        count: uniqueEmotionCount,
      );
    }

    if (positiveRatio <= 0.25) {
      return const MonthlyObservationResult(
        kind: MonthlyObservationKind.mostlyHeavy,
      );
    }

    if (emotionCounts.isNotEmpty) {
      final top = emotionCounts.first;
      return MonthlyObservationResult(
        kind: MonthlyObservationKind.defaultTopEmotion,
        emotion: top.key,
        count: top.value,
      );
    }

    return const MonthlyObservationResult(
      kind: MonthlyObservationKind.defaultThanks,
    );
  }

  /// 요일 라벨(일요일 시작) - [EmotionCalendarScreen]의 요일 헤더와 순서를 맞춘다.
  static const List<String> _weekdayLabels = [
    '일',
    '월',
    '화',
    '수',
    '목',
    '금',
    '토',
  ];

  /// 지금까지 쌓인 [diaryEntries] 전체(최대 200개, 시간 제한 없음)를 요일별로
  /// 나눠서, "어느 요일에 마음이 편안했고/힘들었는지"를 살펴본다.
  ///
  /// 주의: [diaryEntries]에는 시각(시:분) 정보가 없어 "시간대" 분석은 아직
  /// 불가능하다 - 요일(날짜의 weekday)만으로 계산한다.
  ///
  /// 우연에 의한 착시를 줄이기 위해:
  /// - 요일 하나당 최소 3회 이상 기록이 있어야 "비교 대상"으로 인정하고,
  /// - 가장 편안했던 요일과 가장 힘들었던 요일의 긍정 비율 차이가 15%p
  ///   이상일 때만 뚜렷한 패턴으로 판단한다.
  /// - 전체적으로 최소 14회 기록 + 4개 이상의 서로 다른 요일에 데이터가
  ///   있어야만 "데이터가 충분하다"고 보고 관찰 문구를 보여준다.
  static WeekdayEmotionPattern buildWeekdayPattern({
    required List<Map<String, dynamic>> diaryEntries,
  }) {
    final totals = List<int>.filled(7, 0);
    final positives = List<int>.filled(7, 0);
    var totalSessions = 0;

    for (final entry in diaryEntries) {
      final date = _parseDate(entry['date'] as String?);
      final typeName = entry['emotionType'] as String?;
      if (date == null || typeName == null) continue;
      // Dart DateTime.weekday: 월=1 ... 일=7. %7 로 일요일을 0으로 맞춘다.
      final index = date.weekday % 7;
      totals[index]++;
      totalSessions++;
      if (Emotion.byTypeName(typeName).isPositive) positives[index]++;
    }

    final stats = List<WeekdayStat>.generate(7, (i) {
      return WeekdayStat(
        label: _weekdayLabels[i],
        weekdayIndex: i,
        total: totals[i],
        positiveCount: positives[i],
        negativeCount: totals[i] - positives[i],
      );
    });

    final eligible = stats.where((s) => s.total >= 3).toList()
      ..sort((a, b) => (b.positiveRatio ?? 0).compareTo(a.positiveRatio ?? 0));

    WeekdayStat? bestDay;
    WeekdayStat? toughestDay;
    if (eligible.length >= 2) {
      final top = eligible.first;
      final bottom = eligible.last;
      final gap = (top.positiveRatio ?? 0) - (bottom.positiveRatio ?? 0);
      if (gap >= 0.15 && top.label != bottom.label) {
        bestDay = top;
        toughestDay = bottom;
      }
    }

    final distinctWeekdaysWithData = stats.where((s) => s.total > 0).length;
    final hasEnough = totalSessions >= 14 && distinctWeekdaysWithData >= 4;

    return WeekdayEmotionPattern(
      stats: stats,
      bestDay: hasEnough ? bestDay : null,
      toughestDay: hasEnough ? toughestDay : null,
      observationResult: WeekdayObservationResult(
        hasEnoughData: hasEnough,
        bestDay: hasEnough ? bestDay : null,
        toughestDay: hasEnough ? toughestDay : null,
      ),
      totalSessions: totalSessions,
    );
  }

  /// "감정 원인(트리거)" 태그가 붙은 [diaryEntries]를 최근 [days]일(기본
  /// 30일) 기준으로 집계해, "이 감정, 최근엔 유독 어떤 계기 때문이었는지"를
  /// 짚어주는 인사이트를 계산한다.
  ///
  /// [ChoiceScreen]의 트리거 선택 UI는 선택 사항이라 데이터가 태그마다
  /// 듬성듬성 쌓인다 - 우연한 착시를 줄이기 위해 최소 [minEntries]개 이상
  /// 트리거가 달린 기록이 있어야 "패턴"으로 인정한다.
  ///
  /// 특정 부정 감정과 특정 트리거가 자주 함께 등장하면(가장 흔한 조합이
  /// 부정 감정의 60% 이상을 차지) 그 연결을 짚어주고, 그 정도로 뚜렷하지
  /// 않으면 그냥 "가장 흔한 원인" 하나만 담담하게 알려준다.
  static TriggerInsightResult? buildTriggerInsightKind({
    required List<Map<String, dynamic>> diaryEntries,
    int days = 30,
    int minEntries = 5,
  }) {
    final windowEntries = _entriesInWindow(
      diaryEntries: diaryEntries,
      startDaysAgo: days,
      endDaysAgo: 0,
    );

    // 트리거 태그별 총 등장 횟수 + "그 트리거가 붙은 기록 중 부정 감정 비율".
    final triggerCounts = <String, int>{};
    final triggerNegativeCounts = <String, int>{};
    var totalTaggedEntries = 0;

    for (final entry in windowEntries) {
      final triggerIds = (entry['triggers'] as List?)
          ?.whereType<String>()
          .toList();
      if (triggerIds == null || triggerIds.isEmpty) continue;
      totalTaggedEntries++;
      final typeName = entry['emotionType'] as String?;
      final isNegative =
          typeName != null && !Emotion.byTypeName(typeName).isPositive;
      for (final id in triggerIds) {
        triggerCounts[id] = (triggerCounts[id] ?? 0) + 1;
        if (isNegative) {
          triggerNegativeCounts[id] = (triggerNegativeCounts[id] ?? 0) + 1;
        }
      }
    }

    if (totalTaggedEntries < minEntries || triggerCounts.isEmpty) {
      return null;
    }

    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sortedTriggers.first;
    final topTrigger = EmotionTrigger.byId(top.key);

    // 1순위: 가장 흔한 트리거가 압도적으로 부정 감정과 함께 등장할 때
    // (그 트리거가 붙은 기록의 60% 이상이 부정 감정) - 원인-감정 연결을
    // 직접 짚어준다. 최소 3회 이상이어야 우연이 아니라고 판단한다.
    final topNegative = triggerNegativeCounts[top.key] ?? 0;
    if (top.value >= 3 && topNegative / top.value >= 0.6) {
      return TriggerInsightResult(
        kind: TriggerInsightKind.dominantNegativeCause,
        trigger: topTrigger,
        count: top.value,
      );
    }

    // 2순위: 그 정도로 뚜렷하진 않아도, 최근 가장 자주 붙은 트리거는
    // 담담하게 알려준다 - 스스로도 몰랐던 반복 패턴을 알아채는 계기.
    return TriggerInsightResult(
      kind: TriggerInsightKind.topTrigger,
      trigger: topTrigger,
      count: top.value,
    );
  }

  /// Daylio/Bearable식 "마음 흐름 그래프"를 위한 하루당 무드 점수(-1.0 ~ +1.0).
  ///
  /// 이 앱은 매일 별도의 "오늘의 기분"을 1~5로 직접 평가받지 않으므로,
  /// 대신 그날 실제로 기록한 감정([Emotion.isPositive])의 부호와, 선택적으로
  /// 남긴 강도([intensity], 1~5)를 가중치로 써서 하루의 무드를 근사한다.
  /// 강도를 남기지 않았으면 중간 정도 가중치(0.7)를 기본값으로 쓴다.
  static double _entryMoodScore(Map<String, dynamic> entry) {
    final typeName = entry['emotionType'] as String?;
    if (typeName == null) return 0;
    final emotion = Emotion.byTypeName(typeName);
    final intensity = (entry['intensity'] as num?)?.toInt();
    final weight = (intensity != null && intensity >= 1 && intensity <= 5)
        ? intensity / 5.0
        : 0.7;
    return emotion.isPositive ? weight : -weight;
  }

  /// 최근 [days]일(오늘 포함) 동안의 하루 단위 무드 흐름을 계산한다.
  /// 그날 기록이 없는 날은 [MoodTrendPoint.averageScore]가 null이라 차트에서
  /// 자연스럽게 "빈 구간"으로 표시된다.
  static MoodTrendSeries buildMoodTrendSeries({
    required List<Map<String, dynamic>> diaryEntries,
    int days = 14,
  }) {
    final start = _today.subtract(Duration(days: days - 1));
    final byDate = <DateTime, List<Map<String, dynamic>>>{};
    for (final entry in diaryEntries) {
      final date = _parseDate(entry['date'] as String?);
      if (date == null) continue;
      if (date.isBefore(start) || date.isAfter(_today)) continue;
      byDate.putIfAbsent(date, () => []).add(entry);
    }

    final points = <MoodTrendPoint>[];
    var totalSessions = 0;
    var daysWithData = 0;
    var scoreSum = 0.0;
    for (var i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final dayEntries = byDate[date];
      if (dayEntries == null || dayEntries.isEmpty) {
        points.add(
          MoodTrendPoint(date: date, averageScore: null, sessionCount: 0),
        );
        continue;
      }
      final scores = dayEntries.map(_entryMoodScore).toList();
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      points.add(
        MoodTrendPoint(
          date: date,
          averageScore: avg,
          sessionCount: dayEntries.length,
        ),
      );
      totalSessions += dayEntries.length;
      daysWithData++;
      scoreSum += avg;
    }

    final averageScore = daysWithData == 0 ? null : scoreSum / daysWithData;

    // 흐름 방향: 데이터가 있는 날들을 앞/뒤 절반으로 나눠 평균을 비교한다.
    // "판단"이 아니라 "관찰"에 머무르도록 완만한 차이는 그냥 "잔잔함"으로 본다.
    var direction = MoodTrendDirection.notEnoughData;
    final withData = points.where((p) => p.averageScore != null).toList();
    if (withData.length >= 4) {
      final mid = withData.length ~/ 2;
      final firstHalf = withData.sublist(0, mid);
      final secondHalf = withData.sublist(mid);
      final firstAvg =
          firstHalf.map((p) => p.averageScore!).reduce((a, b) => a + b) /
          firstHalf.length;
      final secondAvg =
          secondHalf.map((p) => p.averageScore!).reduce((a, b) => a + b) /
          secondHalf.length;
      final delta = secondAvg - firstAvg;
      if (delta >= 0.25) {
        direction = MoodTrendDirection.improving;
      } else if (delta <= -0.25) {
        direction = MoodTrendDirection.declining;
      } else {
        direction = MoodTrendDirection.steady;
      }
    }

    return MoodTrendSeries(
      points: points,
      windowDays: days,
      totalSessions: totalSessions,
      daysWithData: daysWithData,
      averageScore: averageScore,
      direction: direction,
    );
  }
}

/// [EmotionInsightService.buildSessionInsightKind]가 고를 수 있는 문구 종류.
/// 실제 문구는 화면에서 [AppLocalizations]를 통해 언어별로 골라 붙인다.
enum SessionInsightKind {
  frequentPositive,
  frequentNegative,
  allPositive,
  longAbsence,
  firstEncounter,
}

/// [EmotionInsightService.buildSessionInsightKind]의 계산 결과.
class SessionInsightResult {
  final SessionInsightKind kind;

  /// frequentPositive/frequentNegative에서 쓰이는 "이번 주 등장 횟수".
  final int? count;

  /// longAbsence/firstEncounter에서 쓰이는 감정(라벨 표시용).
  final Emotion? emotion;

  /// longAbsence에서 쓰이는 "며칠 만에 다시 만났는지".
  final int? days;

  const SessionInsightResult({
    required this.kind,
    this.count,
    this.emotion,
    this.days,
  });
}

/// [EmotionInsightService.buildComebackCareKind]가 고를 수 있는 "복귀 케어"
/// 문구 종류. 며칠 쉬었는지에 따라 톤을 살짝 다르게 준다.
enum ComebackCareKind { shortBreak, longBreak }

/// [EmotionInsightService.buildComebackCareKind]의 계산 결과.
class ComebackCareResult {
  final ComebackCareKind kind;

  /// 마지막으로 정원에 다녀간 날로부터 오늘까지 며칠이 지났는지.
  final int days;

  const ComebackCareResult({required this.kind, required this.days});
}

/// [EmotionInsightService.buildNextGoalHintKind]가 고를 수 있는 문구 종류.
enum NextGoalHintKind { almostCollected, treeAlmost, manyUncollected }

/// [EmotionInsightService.buildNextGoalHintKind]의 계산 결과.
class NextGoalHintResult {
  final NextGoalHintKind kind;

  /// almostCollected/manyUncollected에서는 "미수집 개수",
  /// treeAlmost에서는 "다음 단계까지 남은 점수".
  final int count;

  const NextGoalHintResult({required this.kind, required this.count});
}

/// [WeeklyEmotionReport.observationResult]가 고를 수 있는 문구 종류.
enum WeeklyObservationKind {
  noData,
  improvedFromLastWeek,
  declinedFromLastWeek,
  dominantPositive,
  dominantNegative,
  manyNotes,
  mostlyHeavy,
  defaultTopEmotion,
  defaultThanks,
}

/// [EmotionInsightService.buildWeeklyReport]가 계산한 주간 관찰 결과를
/// 언어 중립적으로 담는 데이터. [emotion]/[count]/[deltaPercent]는 [kind]에
/// 따라 화면에서 [AppLocalizations] 문자열에 끼워 넣을 값이다.
class WeeklyObservationResult {
  final WeeklyObservationKind kind;

  /// dominantPositive/dominantNegative/defaultTopEmotion에서 쓰이는 감정.
  final Emotion? emotion;

  /// defaultTopEmotion에서 쓰이는 "그 감정을 몇 번 만났는지".
  final int? count;

  /// improvedFromLastWeek에서 쓰이는 "지난주보다 몇 %p 늘었는지".
  final int? deltaPercent;

  const WeeklyObservationResult({
    required this.kind,
    this.emotion,
    this.count,
    this.deltaPercent,
  });
}

/// [EmotionInsightService.buildWeeklyReport]의 계산 결과를 담는 불변 데이터.
/// 화면(위젯)은 이 값만 받아서 그리기만 하면 되도록 계산과 표시를 분리했다.
class WeeklyEmotionReport {
  /// 최근 7일(오늘 포함) 동안 남긴 일기 항목 총 개수.
  final int totalSessions;

  /// 최근 7일 동안 먹은 감정 개수 총합(eatenCount 합산).
  final int totalEaten;

  /// 감정별 등장 횟수(등장 횟수 내림차순).
  final List<MapEntry<Emotion, int>> emotionCounts;

  final int positiveCount;
  final int negativeCount;

  /// 이번 주 긍정 감정 비율 (0.0 ~ 1.0). 데이터가 없으면 0.0.
  final double positiveRatio;

  /// 지난주 긍정 감정 비율. 지난주 기록이 전혀 없으면 null(비교 불가).
  final double? previousPositiveRatio;

  /// 룰 기반으로 생성된 한 줄 관찰 문구를 언어 중립적으로 담은 결과 - 화면에서
  /// [AppLocalizations]를 통해 언어별 문구를 고를 때 사용한다.
  final WeeklyObservationResult observationResult;

  const WeeklyEmotionReport({
    required this.totalSessions,
    required this.totalEaten,
    required this.emotionCounts,
    required this.positiveCount,
    required this.negativeCount,
    required this.positiveRatio,
    required this.previousPositiveRatio,
    required this.observationResult,
  });

  /// 리포트를 온전히 보여줄 만큼 데이터가 쌓였는지(최소 3회 이상).
  bool get hasEnoughData => totalSessions >= 3;
}

/// [EmotionInsightService.buildMonthlyInsight]의 계산 결과를 담는 불변 데이터.
class MonthlyEmotionInsight {
  /// 이 달에 남긴 일기 총 개수.
  final int totalSessions;

  /// 이 달 감정별 등장 횟수(내림차순 정렬).
  final List<MapEntry<Emotion, int>> emotionCounts;

  /// 이 달에 만난 고유 감정 종류 수(최대 15).
  final int uniqueEmotionCount;

  /// 이 달 최장 연속 기록일(스트릭).
  final int longestStreak;

  /// 주차별(이 달 1주차부터) 긍정 비율 목록. 해당 주에 기록이 없으면 null.
  final List<double?> weeklyPositiveRatios;

  /// 주차별 이번 달 총 기록 수(그래프 막대 높이 정규화용).
  final List<int> weeklySessionCounts;

  /// 이 달 긍정 감정으로 분류된 기록 수.
  final int positiveCount;

  /// 이 달 부정 감정으로 분류된 기록 수.
  final int negativeCount;

  /// 이 달 긍정 감정 비율(0.0~1.0). 기록이 없으면 0.0.
  final double positiveRatio;

  /// 전월(직전 달) 긍정 감정 비율. 전월 기록이 전혀 없으면 null(비교 불가).
  final double? previousPositiveRatio;

  /// 룰 기반으로 생성된 "이 달의 가벼운 분석" 한 줄 관찰 문구를 언어
  /// 중립적으로 담은 결과 - 화면에서 [AppLocalizations]를 통해 언어별
  /// 문구를 고를 때 사용한다.
  final MonthlyObservationResult observationResult;

  const MonthlyEmotionInsight({
    required this.totalSessions,
    required this.emotionCounts,
    required this.uniqueEmotionCount,
    required this.longestStreak,
    required this.weeklyPositiveRatios,
    required this.weeklySessionCounts,
    required this.positiveCount,
    required this.negativeCount,
    required this.positiveRatio,
    required this.previousPositiveRatio,
    required this.observationResult,
  });

  /// 해석 패널을 보여줄 만큼 데이터가 쌓였는지(최소 3회 이상).
  bool get hasEnoughData => totalSessions >= 3;

  /// 이 달 가장 많이 만난 감정(없으면 null).
  Emotion? get topEmotion =>
      emotionCounts.isEmpty ? null : emotionCounts.first.key;

  /// 이 달 두 번째로 많이 만난 감정(있을 때만).
  Emotion? get secondEmotion =>
      emotionCounts.length < 2 ? null : emotionCounts[1].key;

  /// 감정별 등장 비율(0.0~1.0, [emotionCounts]와 같은 내림차순). 전체 분포
  /// 막대 차트를 그릴 때 사용한다. 기록이 없으면 빈 리스트.
  List<MapEntry<Emotion, double>> get emotionRatios {
    if (totalSessions == 0) return const [];
    return emotionCounts
        .map((e) => MapEntry(e.key, e.value / totalSessions))
        .toList();
  }
}

/// [MonthlyEmotionInsight.observationResult]가 고를 수 있는 "이 달의 가벼운
/// 분석" 문구 종류. [WeeklyObservationKind]와 같은 우선순위 판정 철학을
/// 따르되, 월간 표본에 맞게 다양성(diverseEmotions) 후보를 추가했다.
enum MonthlyObservationKind {
  noData,
  improvedFromLastMonth,
  declinedFromLastMonth,
  dominantPositive,
  dominantNegative,
  diverseEmotions,
  mostlyHeavy,
  defaultTopEmotion,
  defaultThanks,
}

/// [EmotionInsightService.buildMonthlyInsight]가 계산한 월간 관찰 결과를
/// 언어 중립적으로 담는 데이터. [emotion]/[count]/[percent]/[deltaPercent]는
/// [kind]에 따라 화면에서 [AppLocalizations] 문자열에 끼워 넣을 값이다.
class MonthlyObservationResult {
  final MonthlyObservationKind kind;

  /// dominantPositive/dominantNegative/defaultTopEmotion에서 쓰이는 감정.
  final Emotion? emotion;

  /// defaultTopEmotion에서 쓰이는 "그 감정을 몇 번 만났는지",
  /// diverseEmotions에서 쓰이는 "이 달에 만난 고유 감정 종류 수".
  final int? count;

  /// dominantPositive/dominantNegative에서 쓰이는 "그 감정이 이 달의 몇
  /// %를 차지했는지".
  final int? percent;

  /// improvedFromLastMonth에서 쓰이는 "전월보다 몇 %p 늘었는지".
  final int? deltaPercent;

  const MonthlyObservationResult({
    required this.kind,
    this.emotion,
    this.count,
    this.percent,
    this.deltaPercent,
  });
}

/// 요일 하나에 대한 집계(총 기록 수 / 긍정 / 부정).
class WeekdayStat {
  final String label;

  /// 일=0 ... 토=6. [label](한글 고정 문자열) 대신 언어별 요일 이름을
  /// [AppLocalizations]로 고르기 위한 값 - `label`은 하위 호환을 위해
  /// 그대로 남겨두고, 새 코드는 이 인덱스를 쓴다.
  final int weekdayIndex;
  final int total;
  final int positiveCount;
  final int negativeCount;

  const WeekdayStat({
    required this.label,
    required this.weekdayIndex,
    required this.total,
    required this.positiveCount,
    required this.negativeCount,
  });

  /// 이 요일의 긍정 비율(0.0~1.0). 기록이 없으면 null.
  double? get positiveRatio => total == 0 ? null : positiveCount / total;
}

/// [EmotionInsightService.buildWeekdayPattern]의 계산 결과를 담는 불변 데이터.
class WeekdayEmotionPattern {
  /// 일~토 순서의 요일별 통계(항상 길이 7).
  final List<WeekdayStat> stats;

  /// 가장 긍정 비율이 높았던 요일(데이터가 뚜렷하지 않으면 null).
  final WeekdayStat? bestDay;

  /// 가장 긍정 비율이 낮았던(힘들었던) 요일(데이터가 뚜렷하지 않으면 null).
  final WeekdayStat? toughestDay;

  /// 룰 기반으로 생성된 한 줄 관찰 문구를 언어 중립적으로 담은 결과 - 화면에서
  /// [AppLocalizations]를 통해 언어별 문구를 고를 때 사용한다.
  final WeekdayObservationResult observationResult;

  /// 전체 기록 수(요일 구분 없이).
  final int totalSessions;

  const WeekdayEmotionPattern({
    required this.stats,
    required this.bestDay,
    required this.toughestDay,
    required this.observationResult,
    required this.totalSessions,
  });

  /// 해석 패널을 보여줄 만큼 데이터가 쌓였는지(최소 14회 이상).
  bool get hasEnoughData => totalSessions >= 14;

  /// 차트에 쓸 최대 기록 수(막대 정규화용, 0 나눗셈 방지로 최소 1).
  int get maxTotal =>
      stats.fold(0, (m, s) => s.total > m ? s.total : m).clamp(1, 1 << 30);
}

/// [EmotionInsightService.buildTriggerInsightKind]가 고를 수 있는 문구 종류.
enum TriggerInsightKind {
  /// 가장 흔한 트리거가 부정 감정과 뚜렷하게(60% 이상) 함께 등장할 때 -
  /// "원인-감정" 연결을 직접 짚어준다.
  dominantNegativeCause,

  /// 그 정도로 뚜렷하진 않지만, 최근 가장 자주 태그된 원인.
  topTrigger,
}

/// [EmotionInsightService.buildTriggerInsightKind]의 계산 결과.
class TriggerInsightResult {
  final TriggerInsightKind kind;

  /// 가장 자주 등장한 트리거(계기) 태그.
  final EmotionTrigger trigger;

  /// 그 트리거가 최근 기간 동안 등장한 횟수.
  final int count;

  const TriggerInsightResult({
    required this.kind,
    required this.trigger,
    required this.count,
  });
}

/// [WeekdayEmotionPattern.observationResult]가 고를 수 있는 문구 종류.
enum WeekdayObservationKind { notEnoughData, hasPattern, noClearPattern }

/// [EmotionInsightService.buildWeekdayPattern]이 계산한 요일별 관찰 결과를
/// 언어 중립적으로 담는 데이터. [bestDay]/[toughestDay]의 [WeekdayStat.weekdayIndex]를
/// 화면에서 [AppLocalizations]로 요일 이름을 고를 때 사용한다.
class WeekdayObservationResult {
  final WeekdayObservationKind kind;
  final WeekdayStat? bestDay;
  final WeekdayStat? toughestDay;

  const WeekdayObservationResult({
    required bool hasEnoughData,
    required this.bestDay,
    required this.toughestDay,
  }) : kind = !hasEnoughData
           ? WeekdayObservationKind.notEnoughData
           : (bestDay != null && toughestDay != null)
           ? WeekdayObservationKind.hasPattern
           : WeekdayObservationKind.noClearPattern;
}

/// [EmotionInsightService.buildMoodTrendSeries]가 계산한 하루 단위 무드 점수.
/// Daylio/Bearable식 "마음 흐름 그래프"의 한 점(=하루)에 해당한다.
class MoodTrendPoint {
  final DateTime date;

  /// 그날 기록의 평균 무드 점수(-1.0 ~ +1.0). 그날 기록이 하나도 없으면 null
  /// - 차트에서는 이 날을 "빈 구간"(점을 잇지 않음)으로 그린다.
  final double? averageScore;

  /// 그날 남긴 일기 항목 수.
  final int sessionCount;

  const MoodTrendPoint({
    required this.date,
    required this.averageScore,
    required this.sessionCount,
  });

  bool get hasData => averageScore != null;
}

/// [EmotionInsightService.buildMoodTrendSeries]가 판단한 전체적인 흐름 방향.
/// 절대 "진단"하지 않고, 앞/뒤 절반 평균의 완만한 비교로만 판단한다.
enum MoodTrendDirection { notEnoughData, improving, steady, declining }

/// [EmotionInsightService.buildMoodTrendSeries]의 계산 결과를 담는 불변 데이터.
/// 화면(위젯)은 이 값만 받아서 그리기만 하면 되도록 계산과 표시를 분리했다.
class MoodTrendSeries {
  /// 오늘을 포함해 과거로 [windowDays]일치, 날짜 오름차순(과거→오늘)으로
  /// 정렬된 하루 단위 점들. 항상 길이가 [windowDays]다(데이터 없는 날도
  /// [MoodTrendPoint.hasData]가 false인 항목으로 포함됨).
  final List<MoodTrendPoint> points;

  final int windowDays;

  /// 창 안에서 실제로 기록한 일기 항목 총 개수.
  final int totalSessions;

  /// 창 안에서 기록이 하나 이상 있었던 날짜 수.
  final int daysWithData;

  /// 기록이 있었던 날들의 평균 무드 점수. 기록이 하나도 없으면 null.
  final double? averageScore;

  final MoodTrendDirection direction;

  const MoodTrendSeries({
    required this.points,
    required this.windowDays,
    required this.totalSessions,
    required this.daysWithData,
    required this.averageScore,
    required this.direction,
  });

  /// 그래프를 보여줄 만큼 데이터가 쌓였는지(최소 4일 이상 기록).
  bool get hasEnoughData => daysWithData >= 4;
}
