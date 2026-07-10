/// 카테고리별 대처 가이드 (솔루션 탭 콘텐츠)
class SolutionGuide {
  final String title;
  final String icon;
  final String subtitle;
  final List<String> steps;
  const SolutionGuide({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.steps,
  });
}

final Map<String, SolutionGuide> breathingGuide = {
  'breathing': const SolutionGuide(
    title: '4-4-6 호흡법',
    icon: '🌬️',
    subtitle: '호흡 명상',
    steps: [
      '편안한 자세로 앉아 눈을 감아보세요.',
      '4초 동안 천천히 코로 숨을 들이마셔요.',
      '4초 동안 숨을 참아요.',
      '6초 동안 입으로 천천히 내쉬어요.',
      '이 과정을 3~5회 반복하며 몸의 긴장을 풀어보세요.',
    ],
  ),
  'boxBreathing': const SolutionGuide(
    title: '박스 호흡 (4-4-4-4)',
    icon: '🟪',
    subtitle: '호흡 명상',
    steps: [
      '네모 상자를 그린다고 상상하며 시작해요.',
      '4초 동안 코로 숨을 들이마셔요 (상자의 첫 변).',
      '4초 동안 숨을 멈춰요 (상자의 두 번째 변).',
      '4초 동안 천천히 내쉬어요 (상자의 세 번째 변).',
      '4초 동안 다시 멈춰요 (상자의 네 번째 변).',
      '이 네 박자를 4~6회 반복하며 마음을 가라앉혀보세요.',
    ],
  ),
  'grounding': const SolutionGuide(
    title: '5-4-3-2-1 그라운딩',
    icon: '🌳',
    subtitle: '알아차림',
    steps: [
      '지금 보이는 것 5가지를 말해보세요.',
      '지금 만져지는 것 4가지를 느껴보세요.',
      '지금 들리는 소리 3가지를 찾아보세요.',
      '지금 느껴지는 냄새 2가지를 찾아보세요.',
      '지금 맛보이는 것 1가지를 떠올려보세요.',
    ],
  ),
  'bodyScan': const SolutionGuide(
    title: '바디 스캔 명상',
    icon: '🧘',
    subtitle: '알아차림',
    steps: [
      '편안히 눕거나 앉아 눈을 감아보세요.',
      '정수리부터 시작해 천천히 얼굴, 목, 어깨로 주의를 옮겨가요.',
      '각 부위에서 느껴지는 감각을 판단 없이 그저 알아차려보세요.',
      '가슴, 배, 팔, 다리를 지나 발끝까지 천천히 내려가요.',
      '몸 전체가 지금 이 순간 존재하고 있음을 느껴보세요.',
    ],
  ),
  'mindfulThought': const SolutionGuide(
    title: '생각 구름 흘려보내기',
    icon: '☁️',
    subtitle: '알아차림',
    steps: [
      '지금 떠오르는 생각을 하나 골라보세요.',
      '그 생각을 하늘에 떠 있는 구름이라고 상상해보세요.',
      '구름을 붙잡지도, 밀어내지도 말고 그저 바라보세요.',
      '구름이 천천히 흘러가며 멀어지는 모습을 지켜보세요.',
      '"나는 생각이 아니라, 생각을 바라보는 사람"임을 떠올려보세요.',
    ],
  ),
  'taichi': const SolutionGuide(
    title: '태극권 - 구름 손 (윈수)',
    icon: '☯️',
    subtitle: '움직이는 명상',
    steps: [
      '어깨너비로 편안히 서서 무릎을 살짝 굽혀보세요.',
      '양손을 배꼽 앞에 두고, 마치 공을 안은 듯한 자세를 만들어요.',
      '숨을 들이마시며 한 손을 천천히 원을 그리듯 위로 올려요.',
      '숨을 내쉬며 반대쪽 손이 원을 그리듯 아래로 내려가요.',
      '양손이 구름을 어루만지듯 느리고 부드럽게 좌우로 교차해요.',
      '10회 정도 반복하며 몸의 무게 중심이 옮겨가는 것을 느껴보세요.',
    ],
  ),
  'walkingMeditation': const SolutionGuide(
    title: '걷기 명상',
    icon: '🚶',
    subtitle: '움직이는 명상',
    steps: [
      '천천히 한 걸음씩 내딛을 준비를 해보세요.',
      '발이 바닥에서 떨어지는 감각에 주의를 기울여요.',
      '발이 공중에서 이동하는 감각을 느껴보세요.',
      '발뒤꿈치, 발바닥, 발가락 순으로 땅에 닿는 감각을 알아차려요.',
      '한 걸음, 한 걸음에 온전히 집중하며 10걸음을 걸어보세요.',
    ],
  ),
  'stretching': const SolutionGuide(
    title: '고양이 스트레칭',
    icon: '🐾',
    subtitle: '움직이는 명상',
    steps: [
      '무릎을 꿇고 양손을 바닥에 짚어 네발 자세를 만들어요.',
      '숨을 들이마시며 등을 아래로 늘어뜨리고 고개를 들어요 (소 자세).',
      '숨을 내쉬며 등을 둥글게 말아 올리고 고개를 숙여요 (고양이 자세).',
      '고양이가 기지개를 켜듯 천천히 5~8회 반복해보세요.',
      '몸의 긴장이 따라 풀리는 것을 느껴보세요.',
    ],
  ),
  'writing': const SolutionGuide(
    title: '감정 흘려쓰기',
    icon: '✍️',
    subtitle: '표현하기',
    steps: [
      '타이머를 5분으로 맞춰보세요.',
      '문법이나 논리를 신경 쓰지 말고 떠오르는 대로 적어보세요.',
      '멈추지 말고 손을 계속 움직여보세요.',
      '다 쓴 후 다시 읽지 않아도 괜찮아요. 그저 흘려보내는 것으로 충분해요.',
    ],
  ),
  'selfCompassion': const SolutionGuide(
    title: '자기 자비 확언',
    icon: '💗',
    subtitle: '표현하기',
    steps: [
      '한 손을 가슴에 얹어보세요.',
      '"지금 나는 힘든 시간을 보내고 있어"라고 말해보세요.',
      '"힘든 것은 누구에게나 있는 일이야"라고 말해보세요.',
      '"나는 나 자신에게 다정할 수 있어"라고 말해보세요.',
    ],
  ),
  'lovingKindness': const SolutionGuide(
    title: '자애 명상',
    icon: '🌸',
    subtitle: '표현하기',
    steps: [
      '편안히 앉아 나 자신을 떠올려보세요.',
      '"내가 평안하기를, 내가 행복하기를" 마음속으로 말해보세요.',
      '가까운 사람을 떠올리며 "당신이 평안하기를" 전해보세요.',
      '조금 어려운 사람을 떠올리며 같은 마음을 보내보세요.',
      '마지막으로 모든 존재를 향해 따뜻한 마음을 넓혀보세요.',
    ],
  ),
  'gratitudeExpansion': const SolutionGuide(
    title: '마음 확장 명상',
    icon: '🌷',
    subtitle: '감사 명상',
    steps: [
      '편안히 앉아 오늘 하루를 천천히 떠올려보세요.',
      '작지만 감사했던 순간 하나를 골라보세요.',
      '그 순간의 기분 좋은 느낌을 가슴 속에서 천천히 넓혀보세요.',
      '그 따뜻함이 몸 전체로 은은하게 퍼져나가는 것을 느껴보세요.',
      '"오늘도 감사한 순간들이 나를 찾아왔다"고 마음속으로 말해보세요.',
    ],
  ),
  'tensionRelease': const SolutionGuide(
    title: '긴장 이완 호흡',
    icon: '🌬️',
    subtitle: '긴장 완화',
    steps: [
      '어깨를 귀 쪽으로 끌어올렸다가, 숨을 내쉬며 툭 떨어뜨려보세요.',
      '코로 깊게 숨을 들이마시며 배가 부풀어 오르는 것을 느껴보세요.',
      '입으로 아주 천천히, 길게 숨을 내쉬며 긴장을 함께 흘려보내요.',
      '몸에서 가장 힘이 들어간 부분을 찾아 그곳에 숨을 불어넣듯 이완해보세요.',
      '이 호흡을 5~6회 반복하며 몸이 조금씩 가벼워지는 것을 느껴보세요.',
    ],
  ),
  'angerCooling': const SolutionGuide(
    title: '감정 진정 호흡',
    icon: '🔥',
    subtitle: '감정 진정',
    steps: [
      '잠시 하던 일을 멈추고, 발바닥이 바닥에 닿는 감각에 집중해보세요.',
      '코로 4초간 숨을 들이마시며 뜨거운 감정을 알아차려보세요.',
      '7초간 숨을 참으며, 그 감정을 판단 없이 그대로 바라봐요.',
      '8초간 아주 천천히 숨을 내쉬며 마음의 온도를 낮춰보세요.',
      '"지금 이 감정은 지나갈 것이다"라고 마음속으로 말해보세요.',
    ],
  ),
  'sleepMeditation': const SolutionGuide(
    title: '잠들기 전 이완 명상',
    icon: '🌙',
    subtitle: '수면 명상',
    steps: [
      '조명을 낮추고 편안한 자세로 누워보세요.',
      '오늘 하루 애써온 몸에게 "고생했어"라고 마음속으로 말해보세요.',
      '발끝부터 정수리까지, 천천히 힘을 빼며 몸을 가라앉혀보세요.',
      '숨을 들이마실 때보다 내쉴 때를 조금 더 길게 가져가보세요.',
      '떠오르는 생각들은 붙잡지 말고 밤하늘로 흘려보내듯 놓아주세요.',
    ],
  ),
  'deepRestMeditation': const SolutionGuide(
    title: '깊은 휴식 명상',
    icon: '🛌',
    subtitle: '깊은 휴식',
    steps: [
      '편안한 곳에 몸을 기대거나 누워보세요.',
      '지금 이 순간, 아무것도 하지 않아도 괜찮다고 스스로에게 말해주세요.',
      '몸의 무게를 바닥에 온전히 맡기며 힘을 풀어보세요.',
      '숨이 들어오고 나가는 자연스러운 리듬을 가만히 지켜보세요.',
      '5분 정도, 그저 존재하는 것만으로 충분한 시간을 가져보세요.',
    ],
  ),
};

/// 솔루션 대분류 (탭 그룹)
class SolutionCategory {
  final String key;
  final String label;
  final String icon;
  final List<String> guideKeys;
  const SolutionCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.guideKeys,
  });
}

const List<SolutionCategory> solutionCategories = [
  SolutionCategory(
    key: 'breath',
    label: '호흡 명상',
    icon: '🌬️',
    guideKeys: ['breathing', 'boxBreathing'],
  ),
  SolutionCategory(
    key: 'awareness',
    label: '알아차림',
    icon: '👁️',
    guideKeys: ['grounding', 'bodyScan', 'mindfulThought'],
  ),
  SolutionCategory(
    key: 'movement',
    label: '움직이는 명상',
    icon: '☯️',
    guideKeys: ['taichi', 'walkingMeditation', 'stretching'],
  ),
  SolutionCategory(
    key: 'expression',
    label: '표현하기',
    icon: '🌸',
    guideKeys: ['writing', 'selfCompassion', 'lovingKindness'],
  ),
  SolutionCategory(
    key: 'calmDown',
    label: '진정 · 이완',
    icon: '🕊️',
    guideKeys: ['tensionRelease', 'angerCooling'],
  ),
  SolutionCategory(
    key: 'restSleep',
    label: '수면 · 휴식',
    icon: '🌙',
    guideKeys: ['sleepMeditation', 'deepRestMeditation'],
  ),
  SolutionCategory(
    key: 'gratitude',
    label: '감사 · 확장',
    icon: '🌷',
    guideKeys: ['gratitudeExpansion'],
  ),
];

/// (하위 호환) 전체 카테고리 버튼 키 목록 - 기존 위젯 호환용
List<String> get solutionCategoryKeys =>
    solutionCategories.expand((c) => c.guideKeys).toList();

Map<String, String> get solutionCategoryLabels => {
  for (final key in solutionCategoryKeys) key: breathingGuide[key]!.title,
};
