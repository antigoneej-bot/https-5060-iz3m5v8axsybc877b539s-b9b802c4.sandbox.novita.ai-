import '../models/letter_context.dart';
import '../models/letter_tags.dart';
import '../models/tagged_sentence.dart';

/// 특정 편지(=특정 시점)에 "지금 활성화된" 태그 값들의 모음.
///
/// [LetterContext]와 현재 시각(now)으로부터 계산되는 값으로, 축마다 여러 값이
/// 동시에 활성화될 수 있습니다(예: last7DaysEmotions 여러 개). 문장의
/// [SentenceTags]와 겹치는 축이 많을수록 그 문장이 "지금 이 순간에 잘
/// 어울리는" 문장이라고 판단합니다(설계서 4.2).
class ActiveTags {
  final List<EmotionTag> emotions;
  final List<GrowthTag> growth;
  final List<IntimacyTag> intimacy;
  final List<SeasonTag> season;
  final List<WeekdayTag> weekday;
  final List<TimeTag> time;
  final List<SpecialDayTag> specialDay;
  final List<CatMoodTag> catMood;
  final List<MeditationTag> meditation;

  const ActiveTags({
    this.emotions = const [],
    this.growth = const [],
    this.intimacy = const [],
    this.season = const [],
    this.weekday = const [],
    this.time = const [],
    this.specialDay = const [],
    this.catMood = const [],
    this.meditation = const [],
  });

  /// [ctx]와 [now]로부터 인사/분위기/공감/위로/마무리/고양이감정 모듈에
  /// 공통으로 쓰일 활성 태그 집합을 계산합니다.
  ///
  /// [catMoodOverride]를 넘기면 ⑦ 모듈 전용으로 미리 뽑아둔 고양이 감정
  /// 태그를 함께 포함합니다(고양이 감정은 컨텍스트에서 바로 파생되지 않고,
  /// 별도의 가중 랜덤 로직으로 결정되므로 - `cat_mood_picker.dart` 참고).
  factory ActiveTags.fromContext(
    LetterContext ctx,
    DateTime now, {
    CatMoodTag? catMoodOverride,
  }) {
    return ActiveTags(
      emotions: [
        ctx.todayEmotion,
        if (ctx.yesterdayEmotion != null) ctx.yesterdayEmotion!,
      ],
      growth: [ctx.growthStage],
      intimacy: [ctx.intimacyStage],
      season: [seasonTagFor(now)],
      weekday: [weekdayTagFor(now)],
      time: [timeTagFor(now)],
      specialDay: [
        if (specialDayTagFor(now) != null) specialDayTagFor(now)!,
      ],
      catMood: [if (catMoodOverride != null) catMoodOverride],
      // 행동제안(⑥) 모듈은 "지금 어떤 명상이 어울리는가"를 판단할 근거가
      // 컨텍스트에 따로 없으므로, 7개 카테고리를 모두 활성화해 동일한
      // 가중치로 후보에 오르게 합니다(그 안에서 반복방지+랜덤으로 결정).
      meditation: MeditationTag.values,
    );
  }
}

/// 월 기준 계절 태그 (한국 기준 대략적인 구분).
SeasonTag seasonTagFor(DateTime now) {
  switch (now.month) {
    case 3:
    case 4:
    case 5:
      return SeasonTag.spring;
    case 6:
    case 7:
    case 8:
      return SeasonTag.summer;
    case 9:
    case 10:
    case 11:
      return SeasonTag.autumn;
    default:
      return SeasonTag.winter;
  }
}

/// dart:core의 [DateTime.weekday](1=월 ~ 7=일)를 [WeekdayTag]로 변환합니다.
WeekdayTag weekdayTagFor(DateTime now) {
  const map = [
    WeekdayTag.mon,
    WeekdayTag.tue,
    WeekdayTag.wed,
    WeekdayTag.thu,
    WeekdayTag.fri,
    WeekdayTag.sat,
    WeekdayTag.sun,
  ];
  return map[now.weekday - 1];
}

/// 시각을 4구간(아침/낮/저녁/밤)으로 나눕니다.
TimeTag timeTagFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 11) return TimeTag.morning;
  if (h >= 11 && h < 17) return TimeTag.noon;
  if (h >= 17 && h < 21) return TimeTag.evening;
  return TimeTag.night;
}

/// 달력상 명확히 알 수 있는 특별한 날(새해/크리스마스)만 자동으로 판별합니다.
/// 생일/100일/1주년처럼 사용자별 데이터가 필요한 값은 여기서 다루지 않고
/// [RelationshipStageService] 쪽에서 계산해 별도로 전달합니다.
SpecialDayTag? specialDayTagFor(DateTime now) {
  if (now.month == 1 && now.day == 1) return SpecialDayTag.newYear;
  if (now.month == 12 && now.day == 25) return SpecialDayTag.christmas;
  return null;
}

/// 문장 태그와 [ActiveTags]의 겹치는 정도를 계산하고, 후보를 걸러내는 유틸.
class TagMatcher {
  /// [pool] 중 [active]와 하나 이상 겹치는 문장만 후보로 남깁니다.
  /// 겹치는 문장이 하나도 없다면(9.3 Fallback), 무태그(범용) 문장으로 대체하고,
  /// 그마저도 없다면 안전하게 전체 풀을 반환합니다(편지 생성은 절대 실패하지 않음).
  static List<TaggedSentence> filter(
    List<TaggedSentence> pool,
    ActiveTags active,
  ) {
    final matched = pool.where((s) => overlapScore(s, active) > 0).toList();
    if (matched.isNotEmpty) return matched;

    final tagless = pool.where((s) => s.tags.isTagless).toList();
    if (tagless.isNotEmpty) return tagless;

    return pool; // 최종 안전장치: 후보가 전혀 없으면 전체 풀 그대로 사용
  }

  /// [sentence]가 [active]와 겹치는 태그 개수(축을 가로질러 합산).
  static int overlapScore(TaggedSentence sentence, ActiveTags active) {
    final tags = sentence.tags;
    int score = 0;
    score += _countOverlap(tags.emotions, active.emotions);
    score += _countOverlap(tags.growth, active.growth);
    score += _countOverlap(tags.intimacy, active.intimacy);
    score += _countOverlap(tags.season, active.season);
    score += _countOverlap(tags.weekday, active.weekday);
    score += _countOverlap(tags.time, active.time);
    score += _countOverlap(tags.specialDay, active.specialDay);
    score += _countOverlap(tags.catMood, active.catMood);
    score += _countOverlap(tags.meditation, active.meditation);
    return score;
  }

  static int _countOverlap<T>(List<T> a, List<T> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final bSet = b.toSet();
    return a.where(bSet.contains).length;
  }
}
