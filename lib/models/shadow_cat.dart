/// 그림자 감정 고양이 모델
/// 사용자가 지금 자신의 기분과 닮은 고양이를 선택하면,
/// 그 고양이의 이야기를 만나고 편지를 쓰고 명상을 추천받게 됩니다.
/// (총 36마리 - 데일리 내면소통 카드로도 함께 사용됩니다)
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
  });

  /// 편지쓰기 안내 문구
  /// (위로/해결이 아니라 '지금 이 감정을 있는 그대로 들여다보는 기록'이라는
  /// 인식·관찰 프레임을 유지합니다)
  String get letterPrompt =>
      '$nameKr에게, 하고 싶은 말이 있나요?\n짧아도 괜찮아요. 이건 나를 들여다보는 기록이에요.';
}
