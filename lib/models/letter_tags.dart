/// 편지 생성 시스템의 태그 정의 (설계서 3장 참고)
///
/// 태그는 9개 축(axis)으로 나뉘고, 문장 하나는 여러 축의 태그를 동시에
/// 가질 수 있습니다. 각 enum은 설계서의 한글 명칭을 그대로 코드로
/// 옮긴 것입니다.
library;

/// 사용자의 감정 (11종)
enum EmotionTag {
  anxious, // 불안
  lonely, // 외로움
  angry, // 분노
  grateful, // 감사
  joyful, // 기쁨
  sad, // 슬픔
  regretful, // 후회
  excited, // 설렘
  calm, // 평온
  weary, // 무기력
  hopeful, // 희망
}

/// 고양이 성장 단계 (기존 CatGrowthStage 4단계 재사용)
enum GrowthTag { baby, teen, young, adult }

/// 친밀도 단계 (5단계)
enum IntimacyTag {
  firstMeet, // 첫만남
  shy, // 낯가림
  friend, // 친구
  family, // 가족
  lifelongFriend, // 평생친구
}

enum SeasonTag { spring, summer, autumn, winter }

enum WeekdayTag { mon, tue, wed, thu, fri, sat, sun }

enum TimeTag { morning, noon, evening, night }

/// 명상/움직임 가이드 (기존 solutions_data.dart 키와는 별개의 상위 분류 -
/// LetterComposerEngine에서 문장 선택용 태그로만 쓰이며, 실제 가이드
/// 연결은 [meditationTagToGuideKeys]에서 처리)
enum MeditationTag {
  breathing, // 호흡
  walking, // 걷기
  teaMeditation, // 차명상
  yoga, // 요가/스트레칭 큰 범주
  stretching, // 스트레칭
  writing, // 글쓰기
  imagineMeditation, // 상상명상
}

enum WeatherTag { sunny, rain, snow, cloudy }

enum SpecialDayTag { birthday, day100, anniversary1y, newYear, christmas }

/// 고양이의 오늘 감정 (⑦ 모듈 전용, 7종 - 사용자 감정과는 별개 축)
enum CatMoodTag { good, sleepy, worried, cheer, excited, playful, quiet }

/// 문장 하나가 가질 수 있는 태그 조합.
/// 축마다 nullable 리스트 - 모든 축을 채울 필요는 없습니다.
class SentenceTags {
  final List<EmotionTag> emotions;
  final List<GrowthTag> growth;
  final List<IntimacyTag> intimacy;
  final List<SeasonTag> season;
  final List<WeekdayTag> weekday;
  final List<TimeTag> time;
  final List<MeditationTag> meditation;
  final List<WeatherTag> weather;
  final List<SpecialDayTag> specialDay;
  final List<CatMoodTag> catMood;

  const SentenceTags({
    this.emotions = const [],
    this.growth = const [],
    this.intimacy = const [],
    this.season = const [],
    this.weekday = const [],
    this.time = const [],
    this.meditation = const [],
    this.weather = const [],
    this.specialDay = const [],
    this.catMood = const [],
  });

  /// 태그가 전혀 없는 "범용 fallback" 문장 여부 (9.3 Fallback 안전장치)
  bool get isTagless =>
      emotions.isEmpty &&
      growth.isEmpty &&
      intimacy.isEmpty &&
      season.isEmpty &&
      weekday.isEmpty &&
      time.isEmpty &&
      meditation.isEmpty &&
      weather.isEmpty &&
      specialDay.isEmpty &&
      catMood.isEmpty;
}

/// 편지 조합에 필요한 8개 모듈 키. UsageHistory 기록/조회에도 그대로 쓰입니다.
class LetterModuleKey {
  static const String greeting = 'greeting'; // ① 인사
  static const String mood = 'mood'; // ② 분위기
  static const String empathy = 'empathy'; // ③ 공감
  static const String memory = 'memory'; // ④ 기억 (조건부)
  static const String comfort = 'comfort'; // ⑤ 위로
  static const String action = 'action'; // ⑥ 행동제안
  static const String catMood = 'catMood'; // ⑦ 고양이감정
  static const String closing = 'closing'; // ⑧ 마무리

  /// 매 편지마다 순서대로 반드시 거치는 모듈 목록 (memory는 조건부라 제외)
  static const List<String> ordered = [
    greeting,
    mood,
    empathy,
    comfort,
    action,
    catMood,
    closing,
  ];
}
