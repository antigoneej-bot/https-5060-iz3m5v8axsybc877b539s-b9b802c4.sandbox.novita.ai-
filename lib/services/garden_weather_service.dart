import '../data/cat_emotion_tone.dart';
import '../models/letter_entry.dart';

/// 정원 날씨의 종류.
/// 사용자의 최근 7일 감정 기록 패턴을 그대로 비추는 '분위기'일 뿐,
/// 좋다/나쁘다를 매기는 성적표가 아닙니다.
enum GardenWeatherKind {
  /// 맑음/햇살 - 긍정적 감정이 우세하거나, 기록이 아직 부족한 기본 상태
  sunny,

  /// 흐린 뒤 갬 - 감정이 골고루 섞여 있거나 뚜렷한 흐름이 없는 상태
  cloudyThenClear,

  /// 이슬비 - 부정적 감정이 우세하지만 강도는 잔잔한 상태
  drizzle,

  /// 안개/흐림 - 부정적 감정이 우세하고 강도도 짙은 상태
  fog,

  /// 비 온 뒤 무지개 - 같은 감정을 3일 연속 마주한 특별한 순간
  rainbowAfterRain,
}

/// 날씨에 따라 아기 고양이가 은은하게 보여줄 활동성.
/// 절대 문구로 설명하지 않고, 움직임의 크기/속도로만 표현합니다.
enum GardenCatActivity { curledUp, gentle, playful }

/// 정원 날씨 계산 결과.
class GardenWeatherState {
  final GardenWeatherKind kind;
  final GardenCatActivity catActivity;

  /// 기록이 충분치 않아 기본(맑음) 상태로 표시된 것인지 여부.
  /// UI에서 별도 문구를 노출하진 않지만, 디버깅/추후 확장을 위해 남겨둡니다.
  final bool isDefaultState;

  const GardenWeatherState({
    required this.kind,
    required this.catActivity,
    this.isDefaultState = false,
  });

  static const GardenWeatherState defaultSunny = GardenWeatherState(
    kind: GardenWeatherKind.sunny,
    catActivity: GardenCatActivity.playful,
    isDefaultState: true,
  );
}

/// 최근 7일간의 감정 기록(LetterEntry)으로부터 정원 날씨를 계산하는 순수
/// 계산 서비스입니다. 상태를 갖지 않고, 판단이 아니라 '있는 그대로의 반영'을
/// 위한 집계만 수행합니다(reflection_service.dart와 동일한 원칙).
class GardenWeatherService {
  const GardenWeatherService._();

  /// [history]는 시간 순서와 무관하게 전체 편지 기록을 받아, 내부에서
  /// [now] 기준 최근 7일만 골라 계산합니다.
  static GardenWeatherState compute(
    List<LetterEntry> history, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final cutoff = todayStart.subtract(const Duration(days: 6));

    final recent = history.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(cutoff) && !d.isAfter(todayStart);
    }).toList();

    // 데이터 부족(신규 유저 등): 최근 7일 중 실제로 기록이 있었던 날이
    // 3일 미만이면 판단하지 않고 기본 상태(맑음)로 표시합니다.
    final recordedDays = <DateTime>{};
    for (final e in recent) {
      recordedDays.add(DateTime(e.date.year, e.date.month, e.date.day));
    }
    if (recordedDays.length < 3) {
      return GardenWeatherState.defaultSunny;
    }

    // 특정 감정(카테고리)이 3일 연속 기록되면, 톤 계산보다 먼저 특수 이벤트를
    // 우선합니다. '연속'은 오늘을 포함해 하루도 빠지지 않고 이어져야 하며,
    // 하루에 여러 번 기록했다면 그날의 가장 마지막(최신) 기록을 대표로 봅니다.
    if (_hasThreeConsecutiveSameCat(history, todayStart)) {
      return const GardenWeatherState(
        kind: GardenWeatherKind.rainbowAfterRain,
        catActivity: GardenCatActivity.gentle,
      );
    }

    int positive = 0, neutral = 0, negative = 0;
    int negativeHigh = 0, negativeLow = 0;
    for (final e in recent) {
      final tone = emotionToneFor(e.catId);
      switch (tone) {
        case EmotionTone.positive:
          positive++;
          break;
        case EmotionTone.neutral:
          neutral++;
          break;
        case EmotionTone.negative:
          negative++;
          if (emotionIntensityFor(e.catId) == EmotionIntensity.high) {
            negativeHigh++;
          } else {
            negativeLow++;
          }
          break;
      }
    }

    final counts = {
      EmotionTone.positive: positive,
      EmotionTone.neutral: neutral,
      EmotionTone.negative: negative,
    };
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    final topTones = counts.entries
        .where((e) => e.value == maxCount)
        .map((e) => e.key)
        .toList();

    // 두 개 이상의 톤이 동률로 우세하면(혼재) 뚜렷한 흐름이 없는 것으로 보고
    // '흐린 뒤 갬'으로 표현합니다.
    if (topTones.length > 1) {
      return const GardenWeatherState(
        kind: GardenWeatherKind.cloudyThenClear,
        catActivity: GardenCatActivity.gentle,
      );
    }

    switch (topTones.single) {
      case EmotionTone.positive:
        return const GardenWeatherState(
          kind: GardenWeatherKind.sunny,
          catActivity: GardenCatActivity.playful,
        );
      case EmotionTone.neutral:
        return const GardenWeatherState(
          kind: GardenWeatherKind.cloudyThenClear,
          catActivity: GardenCatActivity.gentle,
        );
      case EmotionTone.negative:
        if (negativeHigh >= negativeLow) {
          return const GardenWeatherState(
            kind: GardenWeatherKind.fog,
            catActivity: GardenCatActivity.curledUp,
          );
        }
        return const GardenWeatherState(
          kind: GardenWeatherKind.drizzle,
          catActivity: GardenCatActivity.curledUp,
        );
    }
  }

  /// 오늘을 포함해 최근 3일 동안, 그날의 대표(최신) 기록 감정이 모두 같은
  /// 카테고리였는지 확인합니다.
  static bool _hasThreeConsecutiveSameCat(
    List<LetterEntry> history,
    DateTime todayStart,
  ) {
    String? prevCatId;
    for (int i = 0; i < 3; i++) {
      final day = todayStart.subtract(Duration(days: i));
      String? catIdForDay;
      for (final e in history) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d == day) {
          // history는 최신순으로 저장되어 있으므로 이 날짜의 첫 항목이
          // 그날의 가장 최근 기록입니다.
          catIdForDay = e.catId;
          break;
        }
      }
      if (catIdForDay == null) return false;
      if (i == 0) {
        prevCatId = catIdForDay;
      } else if (catIdForDay != prevCatId) {
        return false;
      }
    }
    return true;
  }
}
