/// "나만의 안전 계획" 화면에서 쓰는 섹션 정의.
///
/// 정신건강 위기개입에서 널리 쓰이는 "안전 계획(Safety Planning Intervention)"
/// 구조를 참고했지만, 임상 도구가 아니라 누구나 미리 준비해두면 좋은
/// "마음이 힘들 때를 위한 나만의 메모"로 가볍게 재구성했다. 절대 진단이나
/// 치료를 대신하지 않으며, 작성된 내용은 오직 이 기기(로컬)에만 저장된다.
class SafetyPlanSection {
  final String id;
  final String emoji;
  final String title;
  final String hint;
  final String placeholder;

  const SafetyPlanSection({
    required this.id,
    required this.emoji,
    required this.title,
    required this.hint,
    required this.placeholder,
  });

  static const List<SafetyPlanSection> all = [
    SafetyPlanSection(
      id: 'warning_signs',
      emoji: '🚩',
      title: '나에게 위험 신호가 되는 것들',
      hint: '이런 생각·기분·상황이 나타나면 "지금 조심해야 할 때"라는 뜻이에요.',
      placeholder: '예) 며칠째 잠을 못 잘 때, "다 소용없다"는 생각이 들 때...',
    ),
    SafetyPlanSection(
      id: 'coping_strategies',
      emoji: '🌿',
      title: '혼자서 마음을 가라앉히는 나만의 방법',
      hint: '다른 사람 도움 없이도 스스로 해볼 수 있는 것들이에요.',
      placeholder: '예) 좋아하는 노래 듣기, 산책하기, 몽이랑 감정 정리하기...',
    ),
    SafetyPlanSection(
      id: 'support_people',
      emoji: '🤝',
      title: '도움을 요청할 수 있는 사람들',
      hint: '이름과 연락처를 적어두면, 힘든 순간에 찾아보기 쉬워져요.',
      placeholder: '예) 친구 OOO (010-xxxx-xxxx), 언니, 상담 선생님...',
    ),
    SafetyPlanSection(
      id: 'safe_place',
      emoji: '🏠',
      title: '마음이 편안해지는 장소',
      hint: '잠깐이라도 머물면 마음이 조금 놓이는 곳이 있나요?',
      placeholder: '예) 동네 카페, 가족이 있는 집, 근처 공원 벤치...',
    ),
    SafetyPlanSection(
      id: 'reasons_to_live',
      emoji: '💛',
      title: '나에게 소중한 것들 / 살아야 할 이유',
      hint: '힘든 순간일수록 잊기 쉬운, 나에게 정말 소중한 것들을 적어두세요.',
      placeholder: '예) 우리 강아지, 내년에 가고 싶은 여행, 사랑하는 가족...',
    ),
  ];
}
