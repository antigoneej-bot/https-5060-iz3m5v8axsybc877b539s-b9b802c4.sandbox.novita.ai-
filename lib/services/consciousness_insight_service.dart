/// 무작위 카드와 직접 고른 감정을 나란히 보는 재미용 질문.
import '../models/letter_tags.dart';
import '../data/emotion_tag_mapping.dart';
import 'reflection_service.dart';

// Existing enum names retained for caller compatibility; these are not diagnoses.
enum ConsciousnessRelation { aligned, maskedShadow, hiddenResource, layeredShadow, variedVitality }

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
  static const _negative = {
    EmotionTag.anxious, EmotionTag.lonely, EmotionTag.angry,
    EmotionTag.sad, EmotionTag.regretful, EmotionTag.weary,
  };

  static ConsciousnessInsight? build({
    required String? consciousCatId,
    required String? unconsciousCatId,
  }) {
    if (consciousCatId == null || unconsciousCatId == null) return null;
    final chosen = ReflectionService.catNameFor(consciousCatId);
    final drawn = ReflectionService.catNameFor(unconsciousCatId);
    final same = consciousCatId == unconsciousCatId;
    final chosenNegative = _negative.contains(emotionTagForCatId(consciousCatId));
    final drawnNegative = _negative.contains(emotionTagForCatId(unconsciousCatId));
    final relation = same ? ConsciousnessRelation.aligned
        : !chosenNegative && drawnNegative ? ConsciousnessRelation.maskedShadow
        : chosenNegative && !drawnNegative ? ConsciousnessRelation.hiddenResource
        : chosenNegative && drawnNegative ? ConsciousnessRelation.layeredShadow
        : ConsciousnessRelation.variedVitality;
    return ConsciousnessInsight(
      relation: relation,
      stateDescription: same
          ? '직접 고른 $chosen와 무작위로 만난 카드가 같네요. 반가운 우연이에요. '
            '재미용 카드이며, 숨겨진 마음이나 미래를 알려주는 결과는 아니에요.'
          : '오늘 직접 고른 고양이는 $chosen, 무작위 카드는 $drawn예요. '
            '재미용 카드이며, 서로 다르다고 마음에 모순이나 숨겨진 감정이 있다는 뜻은 아니에요.',
      solution: same
          ? '이 고양이를 처음 골랐을 때 어떤 장면이 떠올랐나요? 원한다면 한 줄 남겨보세요.'
          : '$drawn의 이야기에서 와닿는 부분이 있나요? 없다면 내가 고른 $chosen의 이야기만 돌아봐도 좋아요.',
      comfort: '카드에 나를 맞출 필요는 없어요. 내 마음에 대한 답은 내가 정해요. 그냥 넘겨도 괜찮아요.',
      meditation: '원한다면 주변의 색 하나를 가만히 바라보거나 편안하게 숨을 쉬어보세요. 오늘은 여기까지만 해도 충분해요.',
    );
  }
}
