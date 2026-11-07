/// "몽이의 숨결 도감" - 가이드 호흡/명상 미니 라이브러리(벤치마킹 제안 #5).
///
/// 지금까지 앱에 있던 호흡 연출은 딱 한 종류([BreathingInterstitial]의
/// 4초 들숨 + 4초 날숨, 3회 반복)뿐이었다. Calm/Headspace 같은 앱들은
/// 상황(잠들기 전/불안할 때/집중하고 싶을 때)에 맞는 여러 호흡 기법을
/// 고를 수 있게 하는데, 이 모델은 그 아이디어를 가볍게 들여온다.
///
/// 각 기법은 "들이쉬기 -> (필요하면 멈추기) -> 내쉬기 -> (필요하면 멈추기)"
/// 순서의 사이클을 [cycles]번 반복하는 것으로 통일해서 표현한다. 이렇게
/// 하나의 데이터 모델로 표현해두면, 재생 위젯([BreathingInterstitial])도
/// 하나만 두고 파라미터만 바꿔서 여러 기법을 그대로 재생할 수 있다.
enum BreathingTechniqueId {
  /// 기존에 있던 기본 호흡(4-0-4-0, 3회) - 하위 호환을 위해 그대로 유지.
  calmBreath,

  /// 4-7-8 호흡법(불안할 때) - 들이쉬기보다 내쉬기를 훨씬 길게 가져가
  /// 신경을 가라앉히는 데 흔히 쓰이는 기법.
  anxietyRelief,

  /// 박스 호흡(집중할 때) - 들이쉬기/멈추기/내쉬기/멈추기를 똑같은
  /// 길이로 반복해 리듬감 있게 마음을 정돈한다.
  boxBreathing,

  /// 잠들기 전 호흡 - 들이쉬기보다 내쉬기를 길게, 사이클도 더 여유롭게
  /// 잡아 몸이 스르르 늘어지도록 유도한다.
  sleepWindDown,

  /// 생기를 깨우는 숨(2번 벤치마킹 제안: 감정 선택 -> 맞춤 호흡 자동 제안) -
  /// 피곤/심심함처럼 에너지가 낮은 감정을 골랐을 때 제안되는 기법. 다른
  /// 기법들과 달리 멈추는 구간을 짧게, 내쉬기도 살짝 빠르게 가져가 몸에
  /// 잔잔한 활기를 불어넣는다.
  energizingBreath,
}

class BreathingTechniqueDef {
  final BreathingTechniqueId id;
  final String emoji;

  /// 하위 호환/저장소 로직 공유를 위해 한국어로 고정된 이름/설명 - 화면에서는
  /// [breathing_technique_l10n.dart]의 헬퍼를 통해 다국어로 바꿔서 표시한다.
  final String name;
  final String description;

  final Duration inhale;
  final Duration holdAfterInhale;
  final Duration exhale;
  final Duration holdAfterExhale;
  final int cycles;

  /// 이 기법을 하루에 처음 끝까지 완료했을 때 받는 소량의 빛의 정수
  /// (같은 기법이든 다른 기법이든, 하루에 딱 한 번만 지급된다 - 여러 번
  /// 반복해서 돈벌이처럼 쓰이지 않도록).
  final int rewardLightEssence;

  const BreathingTechniqueDef({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.inhale,
    required this.holdAfterInhale,
    required this.exhale,
    required this.holdAfterExhale,
    required this.cycles,
    required this.rewardLightEssence,
  });

  /// 한 사이클의 총 길이(밀리초).
  int get cycleMs =>
      inhale.inMilliseconds +
      holdAfterInhale.inMilliseconds +
      exhale.inMilliseconds +
      holdAfterExhale.inMilliseconds;

  /// 전체 재생 시간(초, 화면에 "약 N초" 형태로 보여줄 때 사용).
  int get totalSeconds => (cycleMs * cycles / 1000).round();
}

class BreathingTechnique {
  BreathingTechnique._();

  static const List<BreathingTechniqueDef> all = [
    BreathingTechniqueDef(
      id: BreathingTechniqueId.calmBreath,
      emoji: '🌬️',
      name: '차분한 숨',
      description: '들이쉬고 내쉬기만 반복하는 가장 기본적인 호흡이에요. 언제든 편하게 시작해보세요.',
      inhale: Duration(milliseconds: 4000),
      holdAfterInhale: Duration.zero,
      exhale: Duration(milliseconds: 4000),
      holdAfterExhale: Duration.zero,
      cycles: 3,
      rewardLightEssence: 5,
    ),
    BreathingTechniqueDef(
      id: BreathingTechniqueId.anxietyRelief,
      emoji: '🌊',
      name: '불안을 가라앉히는 숨',
      description: '4초 들이쉬고, 7초 멈추고, 8초 길게 내쉬어요. 마음이 조급할 때 특히 도움이 돼요.',
      inhale: Duration(milliseconds: 4000),
      holdAfterInhale: Duration(milliseconds: 7000),
      exhale: Duration(milliseconds: 8000),
      holdAfterExhale: Duration.zero,
      cycles: 3,
      rewardLightEssence: 8,
    ),
    BreathingTechniqueDef(
      id: BreathingTechniqueId.boxBreathing,
      emoji: '🔲',
      name: '집중을 위한 박스 호흡',
      description: '들이쉬고, 멈추고, 내쉬고, 멈추기를 똑같은 길이로 반복해요. 흐트러진 집중을 다잡아줘요.',
      inhale: Duration(milliseconds: 4000),
      holdAfterInhale: Duration(milliseconds: 4000),
      exhale: Duration(milliseconds: 4000),
      holdAfterExhale: Duration(milliseconds: 4000),
      cycles: 4,
      rewardLightEssence: 8,
    ),
    BreathingTechniqueDef(
      id: BreathingTechniqueId.sleepWindDown,
      emoji: '🌙',
      name: '잠들기 전 숨결',
      description: '천천히 들이쉬고 아주 길게 내쉬며, 하루의 긴장을 몸에서 스르르 내려놓아요.',
      inhale: Duration(milliseconds: 4000),
      holdAfterInhale: Duration(milliseconds: 2000),
      exhale: Duration(milliseconds: 8000),
      holdAfterExhale: Duration.zero,
      cycles: 4,
      rewardLightEssence: 8,
    ),
    BreathingTechniqueDef(
      id: BreathingTechniqueId.energizingBreath,
      emoji: '⚡',
      name: '생기를 깨우는 숨',
      description:
          '들이쉬고 살짝 멈춘 뒤, 산뜻하게 내쉬기를 조금 빠른 리듬으로 반복해요. 몸과 마음이 나른할 때 기운을 깨워줘요.',
      inhale: Duration(milliseconds: 2000),
      holdAfterInhale: Duration(milliseconds: 500),
      exhale: Duration(milliseconds: 1500),
      holdAfterExhale: Duration.zero,
      cycles: 5,
      rewardLightEssence: 8,
    ),
  ];

  static BreathingTechniqueDef byId(BreathingTechniqueId id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
