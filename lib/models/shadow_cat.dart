/// 그림자 감정 고양이 모델
/// 사용자가 지금 자신의 기분과 닮은 고양이를 선택하면,
/// 그 고양이의 이야기를 만나고 편지를 쓰고 명상을 추천받게 됩니다.
/// (무료 42마리 + 유료(Basic 구독) 10마리, 총 52마리 - 데일리 내면소통
/// 카드로도 함께 사용됩니다)
class ShadowCat {
  final String id;
  final String nameKr;
  final String nameEn;
  final String emoji;
  final String keyword;
  final String imageAsset;

  /// 이 고양이가 왜 이런 감정을 느끼는지, 제3자(관찰자) 시점의 이야기
  final String story;

  /// 이 감정에 어울리는 추천 명상/움직임 가이드 키 목록 (solutions_data.dart 참조)
  final List<String> meditationKeys;

  /// 데일리 내면소통(카드뽑기)에서 이 카드를 뽑았을 때 보여줄 오늘의 위로 한마디
  final String comfortMessage;

  /// 데일리 내면소통에서 함께 보여줄 오늘의 실천 지침
  final String guidance;

  /// 감정체크(고양이 고르기) 및 새 아기고양이 고르기, 데일리 카드뽑기 등
  /// '새로 선택'하는 화면/로직에 노출할지 여부.
  ///
  /// false인 캐릭터는 정원(전체 목록)에는 그대로 남아있지만, 새로 선택할 수
  /// 있는 목록에서는 제외됩니다. 과거에 이 캐릭터로 남겨진 편지/기록/졸업
  /// 이력 등은 [shadowCatById]로 계속 정상적으로 조회되어 그대로 보존됩니다.
  /// (예: 캐릭터 재배치로 보류된 카드 등)
  final bool selectable;

  /// 유료(Basic 구독) 캐릭터인지 여부.
  ///
  /// true인 캐릭터는 무료 사용자에게도 감정체크 화면에서 항상 노출되지만,
  /// 흐림/저채도의 '안개' 처리로 표시되며, 탭하면 곧바로 결제창으로 넘어가는
  /// 것이 아니라 먼저 이 캐릭터를 짧게 소개하고, 가장 가까운 무료 캐릭터를
  /// 대안으로 안내합니다(강제 잠금이 아니라 '다음 단계로의 초대' 톤 유지).
  final bool isPremium;

  const ShadowCat({
    required this.id,
    required this.nameKr,
    required this.nameEn,
    required this.emoji,
    required this.keyword,
    required this.imageAsset,
    required this.story,
    required this.meditationKeys,
    required this.comfortMessage,
    required this.guidance,
    this.selectable = true,
    this.isPremium = false,
  });

  /// 편지쓰기 안내 문구
  /// (위로/해결이 아니라 '지금 이 감정을 있는 그대로 들여다보는 기록'이라는
  /// 인식·관찰 프레임을 유지합니다)
  String get letterPrompt =>
      '$nameKr에게, 하고 싶은 말이 있나요?\n짧아도 괜찮아요. 이건 나를 들여다보는 기록이에요.';
}
