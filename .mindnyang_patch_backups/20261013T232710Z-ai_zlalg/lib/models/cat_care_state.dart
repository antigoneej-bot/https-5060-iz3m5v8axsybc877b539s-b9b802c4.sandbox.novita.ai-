/// 다마고치식 '마음 돌보기'에서 반려 고양이의 성장 단계.
/// ⚠️ 정책 변경: 이제 반려 고양이는 항상 '아기 고양이(baby)' 단계로만
/// 남습니다. teen/young/adult로 자라나는 성장 및 졸업(졸업 앨범, 새
/// 아기고양이로 넘어가기) 기능은 완전히 제거되었습니다. 다른 enum 값은
/// 과거 데이터/열거형 호환을 위해 남겨두었을 뿐, [CatCareState.stageForGrowthDays]가
/// 항상 [baby]만 반환하므로 실제로는 도달하지 않습니다.
enum CatGrowthStage { baby, teen, young, adult }

/// 마음 온도에 따른 상태(감정) 표현.
/// 숫자보다 직관적으로 지금 상태를 전달하기 위한 4단계 표현입니다.
enum CatMoodState { warm, calm, tired, recovering }

/// 성장 단계 하나에 필요한 출석일수(30일 단위)
const int kDaysPerGrowthStage = 30;

/// 다마고치식 '마음 돌보기'의 현재 상태
/// - temperature: 마음 온도 (0~100). 하루 한 가지 돌봄을 실천하면 +1도,
///   출석(앱을 연 날)마다 +1도, 약속을 지킬 때마다 +1도가 오르고, 100도에 도달하면
///   (구독자에 한해) 포인트로 적립되며 온도는 다시 0도로 시작합니다.
///   쉬었던 날에는 온도가 내려가지 않습니다. 심리 상태 측정값이 아닙니다.
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

  /// 오늘 한 가지 이상의 돌봄을 실천했는지
  bool get allDoneToday => completedCountToday >= 1;

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

  /// 성장 단계 계산. ⚠️ 정책 변경: 항상 [CatGrowthStage.baby]를 반환합니다.
  /// (청년/성체로 자라나는 성장 및 졸업 기능은 제거되었습니다.)
  CatGrowthStage get growthStage => stageForGrowthDays(growthDays);

  /// 누적 출석일수로부터 성장 단계를 계산합니다. 항상 아기 고양이 단계를
  /// 반환합니다(성장 단계 상승/졸업 기능 제거).
  static CatGrowthStage stageForGrowthDays(int days) {
    return CatGrowthStage.baby;
  }

  /// 성장 단계 번호. 항상 0(아기 고양이)입니다.
  int get growthLevelNumber => 0;

  /// 다음 단계까지 남은 출석일수. 더 이상 성장하지 않으므로 항상 null입니다.
  int? get daysUntilNextStage => null;

  /// 성장 단계 이름. 항상 '아기 고양이' 라벨을 반환합니다.
  String get growthStageLabel => '아기 고양이';

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
/// ⚠️ 정책 변경: 이제 항상 아기 고양이 이미지를 반환합니다.
String growthStageArtAsset(CatGrowthStage stage) {
  return 'assets/growth/baby_cat.png';
}
