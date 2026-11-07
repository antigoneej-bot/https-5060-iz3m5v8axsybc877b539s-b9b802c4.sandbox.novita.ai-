/// 감정 일기를 남길 때 "오늘 이 감정, 무엇 때문이었을까요?"에 답할 수 있는
/// 미리 정의된 트리거(계기) 태그 목록.
///
/// 자유 입력 대신 고정된 목록을 쓰는 이유:
/// - 감정 기록 직후는 글을 길게 쓰기 힘든 순간일 수 있어, 탭 한 번으로
///   가볍게 남길 수 있어야 한다(부담 최소화).
/// - 고정된 목록이어야 [EmotionInsightService]에서 나중에 "이 트리거가 가장
///   자주 등장했어요" 같은 통계를 안정적으로 계산할 수 있다.
///
/// 여러 개를 동시에 선택할 수 있으며, 전부 선택하지 않아도 된다(선택 사항).
class EmotionTrigger {
  final String id;
  final String emoji;
  final String label;

  const EmotionTrigger({
    required this.id,
    required this.emoji,
    required this.label,
  });

  static const List<EmotionTrigger> all = [
    EmotionTrigger(id: 'work_study', emoji: '💼', label: '일/학업'),
    EmotionTrigger(id: 'relationship', emoji: '🧑‍🤝‍🧑', label: '관계'),
    EmotionTrigger(id: 'family', emoji: '🏠', label: '가족'),
    EmotionTrigger(id: 'health', emoji: '🩺', label: '건강'),
    EmotionTrigger(id: 'money', emoji: '💰', label: '돈'),
    EmotionTrigger(id: 'sleep', emoji: '😴', label: '잠/피로'),
    EmotionTrigger(id: 'alone', emoji: '🌙', label: '혼자 있음'),
    EmotionTrigger(id: 'sns', emoji: '📱', label: 'SNS'),
    EmotionTrigger(id: 'weather', emoji: '🌦️', label: '날씨'),
    EmotionTrigger(id: 'future', emoji: '🌫️', label: '미래 걱정'),
    EmotionTrigger(id: 'achievement', emoji: '🎉', label: '작은 성취'),
    EmotionTrigger(id: 'etc', emoji: '✨', label: '그 외'),
  ];

  /// id로 트리거를 찾는다. 목록에 없는(과거에 삭제된) id라면 label을 id 그대로
  /// 보여주는 안전한 기본값을 반환한다.
  static EmotionTrigger byId(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => EmotionTrigger(id: id, emoji: '✨', label: id),
    );
  }
}
