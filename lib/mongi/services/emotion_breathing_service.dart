import '../models/breathing_technique.dart';
import '../models/emotion.dart';

/// 2번(벤치마킹 제안: 감정 선택 -> 맞춤 호흡 자동 제안 흐름 연결).
///
/// 게임을 시작하기도 전에, 방금 고른 감정에 어울리는 호흡 기법을 먼저
/// 골라준다. Calm/Headspace 벤치마킹으로 만들어진 [BreathingTechnique]
/// 라이브러리를 "도감"에서 직접 찾아 들어가야만 쓸 수 있던 것에서,
/// 감정 체크인 흐름 안으로 자연스럽게 끌어온 것이다.
///
/// 매칭 기준(에이전트 3중 페르소나 분석 - 게임기획자/사업가/명상가 관점의
/// 제안):
/// - 화/짜증처럼 확 타오르는 감정 -> "불안을 가라앉히는 숨"(4-7-8호흡).
///   내쉬기를 들이쉬기보다 훨씬 길게 가져가는 구조라, 격하게 오른 열을
///   빠르게 가라앉히는 데 임상적으로도 흔히 쓰인다.
/// - 불안/걱정처럼 붕 뜬 채 진정이 안 되는 감정 -> "집중을 위한 박스
///   호흡". 들이쉬기/멈추기/내쉬기/멈추기를 똑같은 길이로 반복하는 규칙적인
///   리듬이, 갈피를 못 잡고 흩어진 주의를 다시 몸의 감각으로 모아준다.
/// - 무기력/지루함처럼 에너지가 낮게 가라앉은 감정 -> "생기를 깨우는 숨"
///   (energizingBreath). 다른 무거운 감정들과 반대로, 오히려 살짝 빠른
///   리듬으로 몸에 활기를 되돌려준다.
/// - 그 외 나머지 감정(슬픔/외로움/두려움/부끄러움/억울함 및 모든 긍정
///   감정)은 특정 기법을 강요하지 않고, 기본값인 "차분한 숨"을 제안한다 -
///   특정 임상적 처방이 필요하다기보다는 그냥 잠깐 숨을 고르는 것만으로도
///   충분한 경우이기 때문이다.
class EmotionBreathingService {
  EmotionBreathingService._();

  static const Set<EmotionType> _hotBurstTypes = {
    EmotionType.anger,
    EmotionType.irritation,
  };

  static const Set<EmotionType> _unsettledTypes = {
    EmotionType.anxiety,
    EmotionType.worry,
  };

  static const Set<EmotionType> _lowEnergyTypes = {
    EmotionType.tired,
    EmotionType.boredom,
  };

  /// 여러 감정을 골랐을 수 있으므로, 목록 중 가장 먼저 매칭되는 감정을
  /// 기준으로 기법 하나를 고른다(우선순위: 화/짜증 > 불안/걱정 > 무기력/
  /// 심심함 > 기본값). 감정을 하나도 고르지 않았다면 그냥 기본값을 준다.
  static BreathingTechniqueDef suggestFor(List<Emotion> emotions) {
    final types = emotions.map((e) => e.type).toSet();
    if (types.any(_hotBurstTypes.contains)) {
      return BreathingTechnique.byId(BreathingTechniqueId.anxietyRelief);
    }
    if (types.any(_unsettledTypes.contains)) {
      return BreathingTechnique.byId(BreathingTechniqueId.boxBreathing);
    }
    if (types.any(_lowEnergyTypes.contains)) {
      return BreathingTechnique.byId(BreathingTechniqueId.energizingBreath);
    }
    return BreathingTechnique.byId(BreathingTechniqueId.calmBreath);
  }

  /// 게임 시작 전 호흡 제안 시트를 띄울 만한 상황인지 여부. 감정을 아예
  /// 고르지 않았다면(이론상 발생하지 않지만 방어적으로) 제안하지 않는다.
  static bool shouldSuggest(List<Emotion> emotions) => emotions.isNotEmpty;
}
