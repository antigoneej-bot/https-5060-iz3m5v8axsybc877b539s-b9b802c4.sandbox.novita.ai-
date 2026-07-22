/// 데일리 내면소통(카드뽑기)에서 "의식(오늘 직접 쓴 편지의 고양이)"과
/// "무의식(완전 무작위로 뽑힌 카드의 고양이)"을 비교해, 칼 융의 그림자
/// 심리학 관점에서 더 깊이 풀어 해석하기 위한 서비스.
///
/// [ReflectionService.synchronicitySentence]가 "같았다/달랐다"는 사실만
/// 담담히 서술하는 반면, 이 서비스는 그 사실이 심리학적으로 어떤 의미를
/// 가질 수 있는지, 어떻게 하면 좋을지, 위로와 응원, 명상법까지 함께
/// 풀어줍니다.
library;

import '../models/letter_tags.dart';
import '../data/emotion_tag_mapping.dart';
import 'reflection_service.dart';

enum ConsciousnessRelation {
  /// 의식과 무의식이 같은 감정을 가리킴 - 통합된 상태
  aligned,

  /// 의식은 긍정적인데 무의식은 부정적인 감정을 보여줌 - 억눌린 그림자
  maskedShadow,

  /// 의식은 부정적인데 무의식은 긍정적인 감정을 보여줌 - 숨겨진 자원
  hiddenResource,

  /// 둘 다 부정적이지만 서로 다른 결 - 여러 겹의 그림자
  layeredShadow,

  /// 둘 다 긍정적이지만 서로 다른 결 - 다양한 생기
  variedVitality,
}

class ConsciousnessInsight {
  final ConsciousnessRelation relation;
  final String stateDescription;
  final String solution;
  final String comfort;
  final String meditation;

  const ConsciousnessInsight({
    required this.relation,
    required this.stateDescription,
    required this.solution,
    required this.comfort,
    required this.meditation,
  });
}

class ConsciousnessInsightService {
  ConsciousnessInsightService._();

  static const Set<EmotionTag> _negative = {
    EmotionTag.anxious,
    EmotionTag.lonely,
    EmotionTag.angry,
    EmotionTag.sad,
    EmotionTag.regretful,
    EmotionTag.weary,
  };

  static bool _isNegative(EmotionTag t) => _negative.contains(t);

  /// [consciousCatId]는 오늘 쓴 편지의 고양이, [unconsciousCatId]는 오늘
  /// 무작위로 뽑힌 카드의 고양이입니다. 둘 중 하나라도 없으면 null.
  static ConsciousnessInsight? build({
    required String? consciousCatId,
    required String? unconsciousCatId,
  }) {
    if (consciousCatId == null || unconsciousCatId == null) return null;

    final consciousName = ReflectionService.catNameFor(consciousCatId);
    final unconsciousName = ReflectionService.catNameFor(unconsciousCatId);
    final consciousTag = emotionTagForCatId(consciousCatId);
    final unconsciousTag = emotionTagForCatId(unconsciousCatId);

    if (consciousCatId == unconsciousCatId) {
      return ConsciousnessInsight(
        relation: ConsciousnessRelation.aligned,
        stateDescription:
            '오늘은 의식적으로 고른 마음($consciousName)과, 아무 생각 없이 무작위로 뽑힌 카드($unconsciousName)가 정확히 같은 곳을 가리켰어요. '
            '융 심리학에서는 이런 순간을 "동시성(Synchronicity)"이라 부르며, 의식과 무의식이 서로 다른 언어로 말하지 않고 하나의 목소리로 정렬된 드문 순간이라고 봐요. '
            '지금 이 감정이 당신 안에서 얼마나 또렷하고 진짜인지를 보여주는 신호예요.',
        solution:
            '이렇게 의식과 무의식이 일치한 날은, 그 감정을 억누르거나 서둘러 넘기지 말고 오늘 하루 중 잠깐이라도 그 감정을 위한 시간을 내어주세요. '
            '이 감정과 관련된 짧은 기록을 남겨두면, 나중에 "내가 그때 진짜 원했던 것"을 되짚어보는 데 큰 도움이 돼요.',
        comfort:
            '무의식까지 같은 곳을 가리켰다는 건, 지금 이 마음이 잠깐의 기분이 아니라 당신 안에 꽤 깊이 자리한 진짜 마음이라는 뜻이에요. 그 마음을 있는 그대로 존중해줘도 괜찮아요.',
        meditation:
            '"내면 합일 명상"을 해보세요. 눈을 감고, 오늘 두 번이나 같은 마음을 보여준 이 감정에게 "네 목소리를 들었어"라고 조용히 말해보세요.',
      );
    }

    final consciousNeg = _isNegative(consciousTag);
    final unconsciousNeg = _isNegative(unconsciousTag);

    if (!consciousNeg && unconsciousNeg) {
      // 의식: 긍정 / 무의식: 부정 → 억눌린 그림자
      return ConsciousnessInsight(
        relation: ConsciousnessRelation.maskedShadow,
        stateDescription:
            '오늘 편지에서는 $consciousName처럼 비교적 밝은 마음을 골랐지만, 무작위로 뽑힌 카드는 $unconsciousName였어요. '
            '이런 차이는 흔하고 자연스러운 일이지만, 융 심리학에서는 의식이 아직 마주하지 못한 감정이 무의식 어딘가에서 조용히 신호를 보내고 있을 가능성으로 읽기도 해요. '
            '겉으로는 괜찮아 보이려 애쓰는 동안, 마음 한켠에는 아직 다 표현되지 못한 감정이 남아있을 수 있어요.',
        solution:
            '오늘 잠깐 시간을 내어, "요즘 애써 괜찮다고 넘기고 있는 감정이 있을까?"를 스스로에게 물어봐 주세요. 답이 바로 떠오르지 않아도 괜찮아요, 질문을 던진 것만으로도 충분한 시작이에요.',
        comfort: '밝은 모습을 보이려 애쓰는 것도, 그 아래 다른 감정을 안고 있는 것도 모두 당신의 진짜 모습이에요. 두 마음 다 있어도 괜찮은 거예요.',
        meditation: '"그림자 인사 명상"을 해보세요. 눈을 감고 "$unconsciousName아, 거기 있었구나. 괜찮아, 너도 내 마음의 일부야"라고 조용히 속으로 말해보세요.',
      );
    }

    if (consciousNeg && !unconsciousNeg) {
      // 의식: 부정 / 무의식: 긍정 → 숨겨진 자원
      return ConsciousnessInsight(
        relation: ConsciousnessRelation.hiddenResource,
        stateDescription:
            '오늘 편지에서는 $consciousName처럼 조금 무거운 마음을 골랐지만, 무작위로 뽑힌 카드는 $unconsciousName였어요. '
            '지금 힘든 감정 아래에도, 무의식은 이미 회복의 힘과 밝은 자원을 품고 있다는 신호로 볼 수 있어요. 지금의 어려움이 전부가 아니라는 뜻이에요.',
        solution: '오늘 무의식이 보여준 $unconsciousName의 기운을 잠깐 떠올려보세요. 지금 힘든 감정과 싸우려 하기보다, 그 밝은 자원이 이미 내 안에 있다는 걸 믿고 작은 행동 하나로 옮겨보세요.',
        comfort: '지금 힘든 시간을 보내고 있어도, 당신 안에는 이미 회복할 힘이 준비되어 있어요. 오늘 무의식이 그 사실을 살짝 보여준 거예요.',
        meditation: '"내면 자원 명상"을 해보세요. 눈을 감고, 예전에 힘들었지만 결국 이겨냈던 순간을 떠올리며 그때의 힘이 지금도 내 안에 있음을 느껴보세요.',
      );
    }

    if (consciousNeg && unconsciousNeg) {
      // 둘 다 부정 - 겹겹의 그림자
      return ConsciousnessInsight(
        relation: ConsciousnessRelation.layeredShadow,
        stateDescription:
            '오늘 편지에서는 $consciousName, 무작위로 뽑힌 카드는 $unconsciousName였어요. 둘 다 결이 다르지만 비슷하게 무거운 감정이에요. '
            '이럴 때는 한 가지 감정 아래에 여러 겹의 그림자가 함께 자리하고 있을 수 있어요. 예를 들어 겉으로는 $consciousName처럼 보이지만, 그 아래에는 $unconsciousName의 결도 함께 있는 거예요.',
        solution: '오늘은 두 감정 중 무엇이 먼저인지 따지지 말고, 둘 다 "지금 내 안에 있는 감정"으로 나란히 인정해주세요. 그중 지금 당장 다루기 쉬운 감정 하나만 골라 작은 돌봄을 실천해보세요.',
        comfort: '여러 감정이 한꺼번에 몰려와도, 그것은 당신이 복잡하고 섬세하게 느낄 수 있는 사람이라는 뜻이에요. 무겁게 느껴져도 당신 잘못이 아니에요.',
        meditation: '"두 그림자 명상"을 해보세요. 숨을 들이쉬며 $consciousName를, 내쉬며 $unconsciousName를 떠올리고, 둘 다에게 "너도 내 마음의 일부구나"라고 말해보세요.',
      );
    }

    // 둘 다 긍정 - 다양한 생기
    return ConsciousnessInsight(
      relation: ConsciousnessRelation.variedVitality,
      stateDescription:
          '오늘 편지에서는 $consciousName, 무작위로 뽑힌 카드는 $unconsciousName였어요. 결은 다르지만 둘 다 밝고 생기 있는 감정이에요. '
          '이런 날은 마음이 한 가지 색으로만 설명되지 않을 만큼 다채롭고 풍요롭다는 신호예요.',
      solution: '오늘 느낀 두 가지 밝은 감정을 모두 인정해주고, 그중 하나를 오늘 하루의 작은 행동(감사 표현, 좋아하는 활동)으로 옮겨보세요.',
      comfort: '오늘처럼 여러 결의 밝은 감정을 동시에 느낄 수 있다는 것 자체가, 당신의 마음이 얼마나 풍요롭고 유연한지를 보여줘요.',
      meditation: '"다채로움 명상"을 해보세요. $consciousName와 $unconsciousName, 두 감정이 마음속에서 나란히 빛나는 모습을 잠시 그려보세요.',
    );
  }
}
