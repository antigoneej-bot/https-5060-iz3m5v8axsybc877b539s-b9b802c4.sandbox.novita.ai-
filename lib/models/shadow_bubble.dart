/// '오늘의 그림자 방울 터뜨리기'에서 사용하는 방울 하나의 상태.
///
/// 방울은 오늘 감정체크(편지쓰기)에서 마주한 그림자 고양이(감정)의 색을
/// 그대로 입고 있습니다. 좋다/나쁘다 판단 없이, "오늘 마주한 감정을 하나씩
/// 가만히 들여다보고 놓아주는" 의식이라는 컨셉을 위해 이 모델은 승패나
/// 점수 랭킹 같은 개념을 전혀 갖지 않습니다.
class ShadowBubble {
  /// 오늘의 방울 목록 안에서의 순번(0부터 시작). 저장/복원 키로 사용합니다.
  final int index;

  /// 이 방울이 어떤 그림자 고양이(감정)의 색을 입고 있는지.
  final String catId;

  /// 이미 터뜨렸는지 여부.
  final bool popped;

  /// 터뜨리지 않고 '묻어두기'를 선택했는지 여부. 오늘 생성된 방울 중
  /// 감정 강도가 가장 높았던 단 하나에만 해당될 수 있습니다. 묻은 방울은
  /// popped와는 별개로 다루어지며(실패/미완료가 아니라 또 다른 놓아줌의
  /// 방식), 완료 판정에서는 popped와 동등하게 취급됩니다.
  final bool buried;

  const ShadowBubble({
    required this.index,
    required this.catId,
    this.popped = false,
    this.buried = false,
  });

  ShadowBubble copyWith({bool? popped, bool? buried}) {
    return ShadowBubble(
      index: index,
      catId: catId,
      popped: popped ?? this.popped,
      buried: buried ?? this.buried,
    );
  }
}
