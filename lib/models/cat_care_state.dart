/// 다마고치식 '마음 돌보기'에서 반려 고양이의 성장 단계.
/// 이제는 돌봄 완료일수가 아니라 '출석일수'(앱을 연 날짜의 누적, 30일 단위)를
/// 기준으로 성장합니다.
/// - baby(0단계): 출석 0~29일
/// - teen(1단계): 출석 30~59일
/// - young(2단계): 출석 60~89일
/// - adult(3단계): 출석 90일 이상 - 선택한 그림자 고양이의 모습으로 완성
enum CatGrowthStage { baby, teen, young, adult }

/// 마음 온도에 따른 상태(감정) 표현.
/// 숫자보다 직관적으로 지금 상태를 전달하기 위한 4단계 표현입니다.
enum CatMoodState { warm, calm, tired, recovering }

/// 성장 단계 하나에 필요한 출석일수(30일 단위)
const int kDaysPerGrowthStage = 30;

/// 다마고치식 '마음 돌보기'의 현재 상태
/// - temperature: 마음 온도 (0~100). 하루 임무(8가지 돌봄)를 모두 완수하면 +1도,
///   출석(앱을 연 날)마다 +1도, 약속을 지킬 때마다 +1도가 오르고, 100도에 도달하면
///   (구독자에 한해) 포인트로 적립되며 온도는 다시 0도로 시작합니다.
///   하루라도 돌보지 않으면 그만큼 온도가 내려갑니다.
/// - growthDays: 누적 출석일수. 이 값에 따라 0→1→2→3단계로 자라납니다.
/// - points: 마음 온도가 100도에 도달할 때마다(구독자 한정) 적립되는 포인트.
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
  final int points;

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
    this.points = 0,
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

  /// 성장 단계 계산 (누적 출석일수 기준, 30일당 1단계)
  CatGrowthStage get growthStage => stageForGrowthDays(growthDays);

  /// 누적 출석일수로부터 성장 단계를 계산합니다. (변화 감지용)
  static CatGrowthStage stageForGrowthDays(int days) {
    if (days >= kDaysPerGrowthStage * 3) return CatGrowthStage.adult;
    if (days >= kDaysPerGrowthStage * 2) return CatGrowthStage.young;
    if (days >= kDaysPerGrowthStage) return CatGrowthStage.teen;
    return CatGrowthStage.baby;
  }

  /// 성장 단계 번호 (0~3)
  int get growthLevelNumber {
    switch (growthStage) {
      case CatGrowthStage.baby:
        return 0;
      case CatGrowthStage.teen:
        return 1;
      case CatGrowthStage.young:
        return 2;
      case CatGrowthStage.adult:
        return 3;
    }
  }

  /// 다음 단계까지 남은 출석일수 (성체면 null)
  int? get daysUntilNextStage {
    switch (growthStage) {
      case CatGrowthStage.baby:
        return kDaysPerGrowthStage - growthDays;
      case CatGrowthStage.teen:
        return kDaysPerGrowthStage * 2 - growthDays;
      case CatGrowthStage.young:
        return kDaysPerGrowthStage * 3 - growthDays;
      case CatGrowthStage.adult:
        return null;
    }
  }

  /// 성장 단계 이름 (단계 번호 + 애칭)
  String get growthStageLabel {
    switch (growthStage) {
      case CatGrowthStage.baby:
        return '0단계 · 아기 고양이';
      case CatGrowthStage.teen:
        return '1단계 · 소년 고양이';
      case CatGrowthStage.young:
        return '2단계 · 청년 고양이';
      case CatGrowthStage.adult:
        return '3단계 · 다 자란 고양이';
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

/// 성장 단계별 공용 성장 아트 이미지 경로.
/// 3단계(adult)는 사용자가 실제로 키우고 있는 그림자 고양이 모습을 보여줘야
/// 하므로, 이 함수는 빈 문자열을 반환합니다 - 호출하는 쪽에서 해당 ShadowCat의
/// imageAsset을 대신 사용해야 합니다.
String growthStageArtAsset(CatGrowthStage stage) {
  switch (stage) {
    case CatGrowthStage.baby:
      return 'assets/growth/baby_cat.png';
    case CatGrowthStage.teen:
      return 'assets/growth/teen_cat.png';
    case CatGrowthStage.young:
      return 'assets/growth/young_cat.png';
    case CatGrowthStage.adult:
      return '';
  }
}
