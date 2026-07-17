/// 감정 카테고리(무료 42 + 유료 10 = 52 그림자 고양이)의 톤(긍정/중립/부정)과
/// 강도(고/저) 분류.
///
/// ⚠️ 이 분류는 오직 '정원 날씨 시스템'의 내부 계산(연출)에만 쓰입니다.
/// cat_palette.dart의 원칙과 동일하게, 사용자에게 "이 감정은 부정적이에요"
/// 같은 낙인성 문구로는 절대 노출되지 않습니다 - 좋다/나쁘다 평가가 아니라
/// 그날의 분위기(날씨)를 자연스럽게 표현하기 위한 내부 참고값일 뿐입니다.
library;

/// 감정의 전체적인 톤.
enum EmotionTone { positive, neutral, negative }

/// 감정의 강도(고/저). 부정적 감정이 우세할 때 안개(고강도)와 이슬비(저강도)를
/// 구분하는 데 사용됩니다.
enum EmotionIntensity { high, low }

class _ToneEntry {
  final EmotionTone tone;
  final EmotionIntensity intensity;
  const _ToneEntry(this.tone, this.intensity);
}

/// shadow_cats_data.dart의 52개 id와 1:1로 대응합니다.
const Map<String, _ToneEntry> _catEmotionTone = {
  'dreamy': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'sad': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'jealous': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'angry': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'proud': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'cautious': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'weary': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'anxious': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'lonely': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'confused': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'nostalgic': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'stubborn': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'vulnerable': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'indifferent': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'impatient': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'needy': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'mischievous': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  'selfCritical': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'grieving': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'hesitant': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'surprised': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  // 캐릭터 재배치: 'sleepy' → '피곤한 고양이'(억누르고 버텨온 지침)
  'sleepy': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'sulky': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'excluded': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'joyful': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'affectionate': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'focused': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  'excited': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'curious': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  'comforted': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'playful': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  // 캐릭터 재배치: 'enchanted' → '모르겠는 고양이'(미분화 상태, 중립·저강도 유지)
  'enchanted': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'serene': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  'studious': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'protective': _ToneEntry(EmotionTone.neutral, EmotionIntensity.low),
  'content': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  // 신규 6마리
  'ashamed': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'wronged': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'hollow': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'grateful': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  'courageous': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'witty': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  // 유료(Basic 구독) 10마리
  'cynical': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'envious': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'hurtFeelings': _ToneEntry(EmotionTone.negative, EmotionIntensity.low),
  'inferior': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'dread': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'guilty': _ToneEntry(EmotionTone.negative, EmotionIntensity.high),
  'openHearted': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
  'creative': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'leaderly': _ToneEntry(EmotionTone.positive, EmotionIntensity.high),
  'convicted': _ToneEntry(EmotionTone.positive, EmotionIntensity.low),
};

/// 감정 카테고리(catId)의 톤을 반환합니다. 알 수 없는 id는 중립으로 처리합니다.
EmotionTone emotionToneFor(String catId) =>
    _catEmotionTone[catId]?.tone ?? EmotionTone.neutral;

/// 감정 카테고리(catId)의 강도를 반환합니다. 알 수 없는 id는 저강도로 처리합니다.
EmotionIntensity emotionIntensityFor(String catId) =>
    _catEmotionTone[catId]?.intensity ?? EmotionIntensity.low;
