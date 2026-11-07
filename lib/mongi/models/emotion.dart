import 'package:flutter/material.dart';

/// 감정 타입. 앞의 10가지는 부정적 감정("그림자 먹기"), 뒤의 5가지는
/// 긍정적 감정("품고 마음에 채우기")이다 - 어떤 감정이든 잠금 없이 있는
/// 그대로 자유롭게 고를 수 있다는 것이 이 앱의 핵심 가치다.
enum EmotionType {
  // 부정적 감정 10가지
  hate,
  anger,
  worry,
  sadness,
  loneliness,
  anxiety,
  shame,
  irritation,
  grievance,
  fear,
  // 긍정적 감정 5가지
  joy,
  gratitude,
  excitement,
  calm,
  confidence,
  // 추가된 감정 5가지 (피곤/심심함은 부정 쪽, 용기/신남/행복은 긍정 쪽)
  tired,
  boredom,
  courage,
  thrill,
  happiness,
}

/// 감정 하나에 대한 모든 정보(이름, 이미지, 컬러, 대사)를 담는 모델
class Emotion {
  final EmotionType type;
  final String label; // 화면에 표시되는 한글 이름
  final String emoji; // 버튼에 쓰는 이모지
  final String monsterAsset; // 감정 몬스터 이미지 경로
  final Color color; // 감정별 포인트 컬러
  final String catQuestion; // 몬스터 등장 시 몽이 대사
  final String healMessage; // 먹고 난 뒤 위로 메시지
  final String gardenIcon; // healMessage 끝에 붙는 이모지와 동일 - 정원 화면에서 이 감정을
  // 치유했을 때 피어나는 상징(꽃/빛/별 등)을 표시할 때 재사용한다.
  final String storyText; // "감정 컬렉션 도감"에서 처음 만났을 때 보여주는 짧은 캐릭터 소개 글.
  // 감정 교육적 가치 + 수집욕구 자극을 위해, 그 감정이 왜 생기고 어떻게
  // 다뤄지면 좋은지를 몽이의 시선에서 다정하게 설명한다.

  const Emotion({
    required this.type,
    required this.label,
    required this.emoji,
    required this.monsterAsset,
    required this.color,
    required this.catQuestion,
    required this.healMessage,
    required this.gardenIcon,
    required this.storyText,
  });

  /// 긍정적 감정인지 여부 (뒤 5가지: 기쁨/감사/설렘/평온/자신감).
  /// 긍정 감정은 "치유"가 아니라 "품고 마음에 채우기"로 문구 톤이 달라진다.
  bool get isPositive => _positiveTypes.contains(type);

  static const Set<EmotionType> _positiveTypes = {
    EmotionType.joy,
    EmotionType.gratitude,
    EmotionType.excitement,
    EmotionType.calm,
    EmotionType.confidence,
    EmotionType.courage,
    EmotionType.thrill,
    EmotionType.happiness,
  };

  /// 저장소에 문자열(EmotionType.name)로 저장된 감정 타입을 다시 Emotion으로 찾는다.
  /// (감정 다이어리처럼 타입 이름만 저장해둔 데이터를 화면에 표시할 때 사용)
  static Emotion byTypeName(String name) {
    return all.firstWhere((e) => e.type.name == name, orElse: () => all.first);
  }

  static const List<Emotion> all = [
    Emotion(
      type: EmotionType.hate,
      label: '미움',
      emoji: '💔',
      monsterAsset: 'assets/mongi/images/monster_hate_bean.png',
      color: Color(0xFF6B5B95),
      catQuestion: '이건... 미움콩이네. 오래 가지고 있었구나.',
      healMessage: '미움이 사라진 자리에\n작은 꽃 한 송이가 피었어요 🌸',
      gardenIcon: '🌸',
      storyText:
          '미움콩은 마음에 오래 담아두면 점점 딱딱해져요. 누군가를 미워하는 마음은 사실 그만큼 소중히 여겼다는 증거이기도 해요. 꺼내서 보여주면, 그 자리에 꽃이 필 수 있어요.',
    ),
    Emotion(
      type: EmotionType.anger,
      label: '화',
      emoji: '😡',
      monsterAsset: 'assets/mongi/images/monster_anger_flame.png',
      color: Color(0xFFE86A5B),
      catQuestion: '화르르가 나왔네. 많이 속상했지.',
      healMessage: '뜨거운 마음이 가라앉고\n따뜻한 빛이 남았어요 ✨',
      gardenIcon: '✨',
      storyText:
          '화르르는 마음이 지켜지지 않았을 때 확 타오르는 감정이에요. 나쁜 게 아니라, "나를 존중해줘"라는 신호랍니다. 잠깐 열을 식히고 나면 따뜻한 빛만 남아요.',
    ),
    Emotion(
      type: EmotionType.worry,
      label: '걱정',
      emoji: '😰',
      monsterAsset: 'assets/mongi/images/monster_worry_cloud.png',
      color: Color(0xFF8C9CB4),
      catQuestion: '걱정구름이 잔뜩 끼어있었네.',
      healMessage: '먹구름이 걷히고\n맑은 하늘이 보이기 시작해요 🌤️',
      gardenIcon: '🌤️',
      storyText:
          '걱정구름은 아직 일어나지 않은 일까지 미리 대비하려는 마음이 만들어내요. 조금은 나를 지키려는 노력이었어요. 구름은 흘러가는 게 원래 하는 일이니, 잠시 지켜봐 줘도 괜찮아요.',
    ),
    Emotion(
      type: EmotionType.sadness,
      label: '슬픔',
      emoji: '😢',
      monsterAsset: 'assets/mongi/images/monster_sadness_drop.png',
      color: Color(0xFF5B9BD5),
      catQuestion: '슬픔물방울이구나. 많이 힘들었겠다.',
      healMessage: '눈물이 마르고\n작은 연못에 별이 비쳐요 💧',
      gardenIcon: '💧',
      storyText:
          '슬픔물방울은 소중한 걸 잃었거나 마음이 다쳤을 때 맺혀요. 참지 않고 흘려보내면, 그 눈물이 고여 작은 연못이 되고 언젠가 별빛이 비치는 날이 와요.',
    ),
    Emotion(
      type: EmotionType.loneliness,
      label: '외로움',
      emoji: '😔',
      monsterAsset: 'assets/mongi/images/monster_loneliness_shadow.png',
      color: Color(0xFF7A6C8C),
      catQuestion: '혼자 웅크리고 있었구나. 내가 옆에 있을게.',
      healMessage: '그림자가 옅어지고\n곁을 지키는 온기가 남았어요 🤍',
      gardenIcon: '🤍',
      storyText:
          '외로움그림자는 누군가와 연결되고 싶은 마음이 클수록 짙어져요. 혼자라는 느낌이 들 땐, 그만큼 함께하고 싶은 마음이 크다는 뜻이에요. 몽이가 옆에 있을게요.',
    ),
    Emotion(
      type: EmotionType.anxiety,
      label: '불안',
      emoji: '😨',
      monsterAsset: 'assets/mongi/images/monster_anxiety_shiver.png',
      color: Color(0xFF6FA8A0),
      catQuestion: '불안돌이가 자꾸 떨고 있었네. 나쁜 생각이 많았구나.',
      healMessage: '떨림이 잦아들고\n마음에 잔잔한 물결이 일어요 🌊',
      gardenIcon: '🌊',
      storyText:
          '불안돌이는 앞일이 어떻게 될지 모를 때 자꾸만 떨려요. 확실하지 않은 걸 견디는 건 누구에게나 힘든 일이에요. 숨을 천천히 쉬면, 떨림도 조금씩 잦아들어요.',
    ),
    Emotion(
      type: EmotionType.shame,
      label: '부끄러움',
      emoji: '😳',
      monsterAsset: 'assets/mongi/images/monster_shame_blush.png',
      color: Color(0xFFE38FB0),
      catQuestion: '부끄럼쟁이구나. 얼굴이 발그레했겠다.',
      healMessage: '움츠렸던 어깨가 펴지고\n따뜻한 미소가 번져요 😊',
      gardenIcon: '😊',
      storyText:
          '부끄럼쟁이는 남들 눈에 어떻게 보일지 신경 쓸 때 얼굴을 붉혀요. 사실 그만큼 진심으로 잘 해내고 싶었다는 뜻이에요. 실수해도 괜찮아요, 몽이는 그런 모습도 좋아해요.',
    ),
    Emotion(
      type: EmotionType.irritation,
      label: '짜증',
      emoji: '😤',
      monsterAsset: 'assets/mongi/images/monster_irritation_spike.png',
      color: Color(0xFFCBA135),
      catQuestion: '까칠이가 잔뜩 곤두서 있었네. 예민했었구나.',
      healMessage: '가시가 살랑살랑 부드러워지고\n산들바람이 불어와요 🍃',
      gardenIcon: '🍃',
      storyText:
          '까칠이는 몸과 마음이 지쳐 여유가 없을 때 가시를 세워요. 짜증이 났다는 건 쉬어야 할 때가 됐다는 신호일 수 있어요. 가시를 내려놓으면 산들바람이 불어와요.',
    ),
    Emotion(
      type: EmotionType.grievance,
      label: '억울함',
      emoji: '😖',
      monsterAsset: 'assets/mongi/images/monster_grievance_knot.png',
      color: Color(0xFF4F6D7A),
      catQuestion: '꽁꽁 묶인 억울함이었구나. 얼마나 답답했을까.',
      healMessage: '엉킨 마음이 스르륵 풀리고\n숨쉬기가 편해졌어요 🎈',
      gardenIcon: '🎈',
      storyText:
          '억울함 매듭은 내 진심이 제대로 전해지지 않았다고 느낄 때 꽁꽁 묶여요. 누군가에게 알아달라고 소리치고 싶었던 마음이었을 거예요. 하나씩 풀다 보면 숨쉬기가 편해져요.',
    ),
    Emotion(
      type: EmotionType.fear,
      label: '두려움',
      emoji: '😱',
      monsterAsset: 'assets/mongi/images/monster_fear_dark.png',
      color: Color(0xFF3E3552),
      catQuestion: '어둠 속에 숨어있던 두려움이네. 이제 괜찮아, 내가 있잖아.',
      healMessage: '어둠이 걷히고\n작은 별빛이 마음을 비춰요 ⭐',
      gardenIcon: '⭐',
      storyText:
          '두려움은 나를 위험으로부터 지키려는 아주 오래된 본능이에요. 무서운 게 있다는 건 그만큼 소중히 지키고 싶은 게 있다는 뜻이죠. 어둠 속에서도 몽이가 함께 있을게요.',
    ),
    // --- 여기부터 긍정적 감정 5가지: "치유"가 아니라 "품고 마음에 채우기" ---
    Emotion(
      type: EmotionType.joy,
      label: '기쁨',
      emoji: '⭐',
      monsterAsset: 'assets/mongi/images/monster_joy_star.png',
      color: Color(0xFFF5C244),
      catQuestion: '반짝반짝 기쁨별이네! 오늘 좋은 일이 있었나 보다.',
      healMessage: '기쁨이 마음 가득 채워지고\n환한 빛으로 남았어요 🌟',
      gardenIcon: '🌟',
      storyText:
          '기쁨별은 작은 행복도 놓치지 않고 알아챘을 때 반짝여요. 기쁜 순간을 마음에 오래 담아두는 연습을 하면, 별빛이 더 환하게 오래 빛난답니다.',
    ),
    Emotion(
      type: EmotionType.gratitude,
      label: '감사',
      emoji: '🧡',
      monsterAsset: 'assets/mongi/images/monster_gratitude_heart.png',
      color: Color(0xFFE8935B),
      catQuestion: '따뜻한 감사하트구나. 누군가에게 고마운 마음이 있었나 봐.',
      healMessage: '고마운 마음이 몽이 품에도\n따뜻하게 스며들었어요 💛',
      gardenIcon: '💛',
      storyText:
          '감사하트는 누군가의 다정함을 알아챘을 때 따뜻하게 커져요. 고맙다는 말 한마디가 상대의 마음에도 하트를 하나 더 심어준답니다.',
    ),
    Emotion(
      type: EmotionType.excitement,
      label: '설렘',
      emoji: '💖',
      monsterAsset: 'assets/mongi/images/monster_excitement_cloud.png',
      color: Color(0xFFFF9FC6),
      catQuestion: '두근두근 설렘구름이네! 무슨 좋은 일을 기다리는 거야?',
      healMessage: '두근거림이 몽이에게도 전해져서\n마음이 살짝 붕 떠올랐어요 🎈',
      gardenIcon: '🎈',
      storyText:
          '설렘구름은 앞으로 다가올 무언가를 기대할 때 두둥실 떠올라요. 결과가 어떻든, 기다리는 그 시간 자체가 이미 선물 같은 순간이에요.',
    ),
    Emotion(
      type: EmotionType.calm,
      label: '평온',
      emoji: '💧',
      monsterAsset: 'assets/mongi/images/monster_calm_wave.png',
      color: Color(0xFF5FB8AE),
      catQuestion: '잔잔한 평온물결이구나. 마음이 고요하고 편안했나 봐.',
      healMessage: '고요한 마음이 정원에도 번져서\n잔잔한 물결이 일어요 🌊',
      gardenIcon: '🌊',
      storyText:
          '평온물결은 아무 일도 없어야만 생기는 게 아니에요. 있는 그대로의 나를 받아들일 때 마음 깊은 곳에서부터 잔잔하게 퍼져 나가요.',
    ),
    Emotion(
      type: EmotionType.confidence,
      label: '자신감',
      emoji: '🏅',
      monsterAsset: 'assets/mongi/images/monster_confidence_badge.png',
      color: Color(0xFFE0A72E),
      catQuestion: '씩씩한 자신감뱃지네! 오늘 뭔가 해냈구나, 대단해.',
      healMessage: '씩씩한 마음이 몽이에게도 옮아서\n어깨가 활짝 펴졌어요 💪',
      gardenIcon: '💪',
      storyText:
          '자신감뱃지는 작은 시도라도 스스로 해냈을 때 반짝 달려요. 결과보다 시도한 그 순간을 인정해주는 게, 뱃지를 더 많이 모으는 비결이에요.',
    ),
    // --- 여기부터 추가된 감정 5가지 ---
    Emotion(
      type: EmotionType.tired,
      label: '피곤',
      emoji: '😴',
      monsterAsset: 'assets/mongi/images/monster_tired_droopy.png',
      color: Color(0xFF8B8FA3),
      catQuestion: '나른한 피곤이네. 오늘 많이 애썼구나.',
      healMessage: '무거웠던 눈꺼풀이 스르륵 감기고\n포근한 잠이 찾아와요 🌙',
      gardenIcon: '🌙',
      storyText:
          '피곤이는 몸과 마음이 열심히 하루를 살아냈다는 증거예요. 애쓴 나를 다그치기보다 잠깐 눈을 감고 쉬어주면, 다음 날 다시 통통 튀어 오를 힘이 생겨요.',
    ),
    Emotion(
      type: EmotionType.boredom,
      label: '심심함',
      emoji: '🥱',
      monsterAsset: 'assets/mongi/images/monster_boredom_swirl.png',
      color: Color(0xFFA9B4B8),
      catQuestion: '하품 나는 심심함이구나. 뭔가 재미있는 게 필요했나 봐.',
      healMessage: '멍하던 마음에 작은 호기심이\n동그라미를 그리며 피어나요 🌀',
      gardenIcon: '🌀',
      storyText:
          '심심이는 딱히 할 일이 없을 때 마음이 텅 빈 것처럼 느껴져서 찾아와요. 사실 심심함은 새로운 걸 하고 싶다는 신호이기도 해요. 가만히 있다 보면 뜻밖의 재미난 생각이 떠오르기도 한답니다.',
    ),
    Emotion(
      type: EmotionType.courage,
      label: '용기',
      emoji: '🦁',
      monsterAsset: 'assets/mongi/images/monster_courage_shield.png',
      color: Color(0xFFE8734A),
      catQuestion: '씩씩한 용기 방패네! 무서운 걸 마주하고도 한 발 나아갔구나.',
      healMessage: '두근거리던 마음이 단단해지고\n몽이 가슴에도 뜨거운 힘이 차올라요 🔥',
      gardenIcon: '🔥',
      storyText:
          '용기 방패는 무섭지 않아서가 아니라, 무서워도 한 걸음 내딛었을 때 반짝 빛나요. 떨리는 마음을 안고도 해낸 그 순간이 가장 용감한 순간이에요.',
    ),
    Emotion(
      type: EmotionType.thrill,
      label: '신남',
      emoji: '🎉',
      monsterAsset: 'assets/mongi/images/monster_thrill_spark.png',
      color: Color(0xFFFFC93C),
      catQuestion: '팡팡 튀는 신남이네! 신나는 일이 생겼구나!',
      healMessage: '통통 튀는 기운이 몽이에게도 옮아서\n온몸이 들썩들썩해졌어요 🎊',
      gardenIcon: '🎊',
      storyText:
          '신남이는 지금 이 순간이 너무 즐거워서 몸이 먼저 들썩일 때 튀어나와요. 설렘이 앞으로 올 일을 기대하는 두근거림이라면, 신남이는 지금 당장 터지는 신나는 에너지예요.',
    ),
    Emotion(
      type: EmotionType.happiness,
      label: '행복',
      emoji: '🌻',
      monsterAsset: 'assets/mongi/images/monster_happiness_sun.png',
      color: Color(0xFFFFB84D),
      catQuestion: '포근한 행복 햇살이네. 마음 가득 따뜻했나 보다.',
      healMessage: '따스한 볕이 마음 구석구석까지 스며들어\n은은하게 오래 남아요 ☀️',
      gardenIcon: '☀️',
      storyText:
          '행복 햇살은 반짝하고 사라지는 기쁨과 달리, 잔잔하고 오래도록 마음을 데워줘요. 특별한 일이 없어도 하루하루가 괜찮다고 느껴질 때, 이 햇살이 은은하게 비춘답니다.',
    ),
  ];
}
