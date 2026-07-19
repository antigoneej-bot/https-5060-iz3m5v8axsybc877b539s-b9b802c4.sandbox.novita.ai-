import '../models/letter_entry.dart';
import '../models/letter_context.dart';
import '../models/letter_tags.dart';
import '../models/cat_care_state.dart';
import '../data/emotion_tag_mapping.dart';
import '../data/shadow_cats_data.dart';
import 'relationship_stage_service.dart';

/// 기존 `AppStateProvider.history`/`CatCareProvider.state`/`StorageService`의
/// 데이터로부터 [LetterContext]를 조립하는 순수 계산 유틸리티.
///
/// 화면/Provider와 결합하지 않고 필요한 값만 인자로 받아 조립하므로,
/// 어디서든(Provider 내부, 위젯, 테스트) 손쉽게 재사용할 수 있습니다.
class LetterContextBuilder {
  /// [history]는 특정 고양이(catId)의 전체 편지 기록(어떤 순서든 무관 -
  /// 내부에서 날짜순으로 다시 정렬합니다).
  static LetterContext build({
    required String catId,
    required List<LetterEntry> history,
    required CatGrowthStage growthStage,
    required int visitStreak,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final catHistory = history.where((e) => e.catId == catId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // 최신순

    final todayEmotion = catHistory.isNotEmpty
        ? emotionTagForCatId(catHistory.first.catId)
        : EmotionTag.calm;

    final yesterdayEntry = _entryForDaysAgo(catHistory, ref, 1);
    final yesterdayEmotion = yesterdayEntry != null
        ? emotionTagForCatId(yesterdayEntry.catId)
        : null;

    final last7 = _entriesWithinDays(catHistory, ref, 7)
        .map((e) => emotionTagForCatId(e.catId))
        .toList();
    final last30 = _entriesWithinDays(catHistory, ref, 30)
        .map((e) => emotionTagForCatId(e.catId))
        .toList();

    final todayEntry = _entryForDaysAgo(catHistory, ref, 0);

    final meditationSucceededYesterday =
        yesterdayEntry?.meditationKey != null &&
        yesterdayEntry!.meditationKey!.isNotEmpty;
    final meditationStreak = _computeMeditationStreak(catHistory, ref);
    final skipStreak = _computeMeditationSkipStreak(catHistory, ref);

    final firstLetterDate = catHistory.isEmpty
        ? null
        : catHistory.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final intimacyStage = RelationshipStageService.calcIntimacyFromDate(
      firstLetterDate,
      ref,
    );

    // 오늘 보낸 편지의 그림자 고양이(catId) 전용 위로/지침을 조회합니다.
    // 편지를 보낼 때 고른 그림자 고양이는 항상 catId 그 자신이므로(사용자가
    // "다친 고양이"에게 편지를 쓰면 catId == 'vulnerable'), 이 고양이가 가진
    // comfortMessage를 그대로 답장에 실어야 "보낸 편지와 답장의 감정이
    // 서로 맞지 않는" 문제가 생기지 않습니다.
    String? catComfortMessage;
    String? catGuidance;
    try {
      final companion = shadowCatById(catId);
      catComfortMessage = companion.comfortMessage;
      catGuidance = companion.guidance;
    } catch (_) {
      // 알 수 없는 catId인 경우(테스트 등) 범용 EmotionTag 문장 풀로
      // 안전하게 폴백합니다.
    }

    return LetterContext(
      catId: catId,
      todayEmotion: todayEmotion,
      yesterdayEmotion: yesterdayEmotion,
      last7DaysEmotions: last7,
      last30DaysEmotions: last30,
      todayLetterText: todayEntry?.letterText,
      yesterdayLetterText: yesterdayEntry?.letterText,
      recentKeywords: const [],
      meditationSucceededYesterday: meditationSucceededYesterday,
      meditationStreak: meditationStreak,
      recentMeditationSkipStreak: skipStreak,
      visitStreak: visitStreak,
      growthStage: _mapGrowthStage(growthStage),
      intimacyStage: intimacyStage,
      now: ref,
      catComfortMessage: catComfortMessage,
      catGuidance: catGuidance,
    );
  }

  static GrowthTag _mapGrowthStage(CatGrowthStage stage) {
    switch (stage) {
      case CatGrowthStage.baby:
        return GrowthTag.baby;
      case CatGrowthStage.teen:
        return GrowthTag.teen;
      case CatGrowthStage.young:
        return GrowthTag.young;
      case CatGrowthStage.adult:
        return GrowthTag.adult;
    }
  }

  static LetterEntry? _entryForDaysAgo(
    List<LetterEntry> sortedDesc,
    DateTime ref,
    int daysAgo,
  ) {
    final target = DateTime(ref.year, ref.month, ref.day).subtract(
      Duration(days: daysAgo),
    );
    for (final e in sortedDesc) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d == target) return e;
    }
    return null;
  }

  static List<LetterEntry> _entriesWithinDays(
    List<LetterEntry> sortedDesc,
    DateTime ref,
    int days,
  ) {
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final cutoff = todayStart.subtract(Duration(days: days - 1));
    return sortedDesc.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(cutoff) && !d.isAfter(todayStart);
    }).toList();
  }

  /// 오늘(또는 가장 최근 편지)부터 거슬러 올라가며, 명상을 실천한 날이
  /// 며칠 연속으로 이어졌는지 계산합니다. 편지를 쓰지 않은 날이 하루라도
  /// 있으면 그 지점에서 스트릭이 끊깁니다.
  static int _computeMeditationStreak(
    List<LetterEntry> sortedDesc,
    DateTime ref,
  ) {
    int streak = 0;
    for (int i = 0; i < 60; i++) {
      final entry = _entryForDaysAgo(sortedDesc, ref, i);
      if (entry == null) break;
      if (entry.meditationKey == null || entry.meditationKey!.isEmpty) break;
      streak++;
    }
    return streak;
  }

  /// 어제부터 거슬러 올라가며, 명상 제안을 연속으로 건너뛴(=meditationKey가
  /// 비어있는) 편지 개수를 계산합니다(설계서 8.2 - "그냥 안부형" 전환 판단용).
  /// 오늘 편지는 아직 명상 여부가 결정되지 않았으므로 어제부터 계산합니다.
  static int _computeMeditationSkipStreak(
    List<LetterEntry> sortedDesc,
    DateTime ref,
  ) {
    int streak = 0;
    for (int i = 1; i <= 60; i++) {
      final entry = _entryForDaysAgo(sortedDesc, ref, i);
      if (entry == null) break;
      if (entry.meditationKey != null && entry.meditationKey!.isNotEmpty) {
        break;
      }
      streak++;
    }
    return streak;
  }
}
