/// 다마고치식 '마음 돌보기'에서 반려 고양이의 성장 단계 (4단계)
/// - baby: 처음 시작 (0~2일 돌봄)
/// - teen: 소년 고양이 (3~5일 돌봄)
/// - young: 청년 고양이 (6~9일 돌봄)
/// - adult: 다 자란 고양이 - 선택한 그림자 고양이의 모습으로 완성 (10일 이상 돌봄)
enum CatGrowthStage { baby, teen, young, adult }

/// 마음 온도에 따른 상태(감정) 표현.
/// 숫자보다 직관적으로 지금 상태를 전달하기 위한 4단계 표현입니다.
enum CatMoodState { warm, calm, tired, recovering }

/// 다마고치식 '마음 돌보기'의 현재 상태
/// - temperature: 마음 온도 (0~100). 매일 몸(밥/물/목욕/청소)과 마음(호흡명상/걷기명상/
///   마음기록/감사쓰기)을 모두 돌보면 유지·상승하고, 하루라도 돌보지 않으면 1도씩 내려갑니다.
/// - growthDays: 정성껏 모두 돌본 날의 누적 일수. 이 값에 따라 아기 → 청년 → 성체로 자라납니다.
class CatCareState {
  final int temperature;
  final bool fedToday;
  final bool wateredToday;
  final bool bathedToday;
  final bool cleanedToday;
  final bool breathingDoneToday;
  final bool walkingDoneToday;
  final bool journalingDoneToday;
  final bool gratitudeDoneToday;
  final String companionCatId;
  final int growthDays;

  const CatCareState({
    required this.temperature,
    required this.fedToday,
    required this.wateredToday,
    required this.bathedToday,
    required this.cleanedToday,
    this.breathingDoneToday = false,
    this.walkingDoneToday = false,
    this.journalingDoneToday = false,
    this.gratitudeDoneToday = false,
    required this.companionCatId,
    this.growthDays = 0,
  });

  /// 몸을 돌보는 4가지 미션(밥/물/목욕/청소)을 모두 마쳤는지
  bool get bodyCareDoneToday =>
      fedToday && wateredToday && bathedToday && cleanedToday;

  /// 마음을 돌보는 4가지 미션(호흡명상/걷기명상/마음기록/감사쓰기)을 모두 마쳤는지
  bool get mindCareDoneToday =>
      breathingDoneToday &&
      walkingDoneToday &&
      journalingDoneToday &&
      gratitudeDoneToday;

  /// 오늘의 돌봄 미션 8가지를 모두 마쳤는지
  bool get allDoneToday => bodyCareDoneToday && mindCareDoneToday;

  /// 오늘 완료한 미션 수 (0~8)
  int get completedCountToday => [
    fedToday,
    wateredToday,
    bathedToday,
    cleanedToday,
    breathingDoneToday,
    walkingDoneToday,
    journalingDoneToday,
    gratitudeDoneToday,
  ].where((v) => v).length;

  /// 성장 단계 계산 (누적 돌봄 일수 기준, 4단계)
  CatGrowthStage get growthStage {
    if (growthDays >= 10) return CatGrowthStage.adult;
    if (growthDays >= 6) return CatGrowthStage.young;
    if (growthDays >= 3) return CatGrowthStage.teen;
    return CatGrowthStage.baby;
  }

  /// 누적 돌봄 일수로부터 성장 단계를 계산합니다. (변화 감지용)
  static CatGrowthStage stageForGrowthDays(int days) {
    if (days >= 10) return CatGrowthStage.adult;
    if (days >= 6) return CatGrowthStage.young;
    if (days >= 3) return CatGrowthStage.teen;
    return CatGrowthStage.baby;
  }

  /// 다음 단계까지 남은 돌봄 일수 (성체면 null)
  int? get daysUntilNextStage {
    switch (growthStage) {
      case CatGrowthStage.baby:
        return 3 - growthDays;
      case CatGrowthStage.teen:
        return 6 - growthDays;
      case CatGrowthStage.young:
        return 10 - growthDays;
      case CatGrowthStage.adult:
        return null;
    }
  }

  /// 성장 단계 이름
  String get growthStageLabel {
    switch (growthStage) {
      case CatGrowthStage.baby:
        return '아기 고양이';
      case CatGrowthStage.teen:
        return '소년 고양이';
      case CatGrowthStage.young:
        return '청년 고양이';
      case CatGrowthStage.adult:
        return '다 자란 고양이';
    }
  }

  /// 마음 온도에 따른 상태(4단계)
  CatMoodState get moodState {
    if (temperature >= 75) return CatMoodState.warm;
    if (temperature >= 50) return CatMoodState.calm;
    if (temperature >= 25) return CatMoodState.tired;
    return CatMoodState.recovering;
  }

  /// 온도에 따른 기분 상태 문구 (4단계: 따뜻해요/평온해요/지쳤어요/회복 중이에요)
  String get moodLabel {
    switch (moodState) {
      case CatMoodState.warm:
        return '따뜻해요';
      case CatMoodState.calm:
        return '평온해요';
      case CatMoodState.tired:
        return '지쳤어요';
      case CatMoodState.recovering:
        return '회복 중이에요';
    }
  }

  /// 온도에 따른 표정 이모지 (4단계: 😊/🌤/🌧/🌱)
  String get moodEmoji {
    switch (moodState) {
      case CatMoodState.warm:
        return '😊';
      case CatMoodState.calm:
        return '🌤';
      case CatMoodState.tired:
        return '🌧';
      case CatMoodState.recovering:
        return '🌱';
    }
  }
}
