export 'meditation_media_data.dart';
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

/// 명상/움직임 가이드의 안내 영상이 들어갈 자리(에셋 경로) 규칙.
///
/// ⚠️ 개발자 인수인계 안내 ⚠️
/// 명상 영상을 촬영/제작해서 넣고 싶다면, 아래 규칙에 맞춰 파일 이름을
/// 지어 `assets/video/meditation/` 폴더에 넣기만 하면 됩니다. 코드를
/// 추가로 수정할 필요가 없습니다 — [MeditationVideoPlayer]가 해당
/// 파일이 있으면 자동으로 "영상으로 따라하기" 재생 버튼을 보여주고,
/// 파일이 없으면 지금처럼 텍스트 가이드만 조용히 보여줍니다.
///
/// 예) '태극권 - 구름 손' 가이드(키: 'taichi')의 영상을 넣고 싶다면:
///   assets/video/meditation/taichi.mp4
///
/// 전체 가이드 키 목록은 [breathingGuide]의 키(= 아래 맵의 key)를 참고하세요.
/// (breathing, boxBreathing, grounding, bodyScan, taichi, walkingMeditation …)
String meditationVideoAssetPath(String guideKey) =>
    'assets/video/meditation/$guideKey.mp4';

final Map<String, SolutionGuide> breathingGuide = {
  'singingBowlRest': const SolutionGuide(
    title: '싱잉볼의 깊은 울림 · 5분',
    icon: '🔔',
    subtitle: '시작과 마무리 안내 · 싱잉볼 3종의 울림',
    steps: [
      '편하게 앉거나 누워 작은 볼륨으로 시작해 주세요.',
      '처음 목소리 안내를 따라 자세를 잡고 평소처럼 자연스럽게 숨 쉬세요.',
      '중간 약 4분은 목소리 없이 싱잉볼의 소리와 여운을 듣는 시간이에요.',
      '마지막 안내가 들리면 손발을 천천히 움직이고 자신의 속도로 돌아오세요.',
    ],
  ),
  'fireplaceRest': const SolutionGuide(
    title: '불멍 · 3분',
    icon: '🔥',
    subtitle: '장작 이미지와 실제 장작 타는 소리',
    steps: [
      '편하게 앉거나 누워 작은 볼륨으로 재생해 주세요.',
      '따뜻한 장작 이미지를 바라보거나 눈을 감고 소리에 귀를 기울여 보세요.',
      '숨은 평소처럼 쉬세요. 생각이 떠오르면 다시 장작 소리로 돌아와도 좋아요.',
    ],
  ),
  'rainThunderRest': const SolutionGuide(
    title: '빗소리와 먼 천둥 · 3분',
    icon: '🌧️',
    subtitle: '목소리 안내 없이 듣는 자연음 명상',
    steps: [
      '편하게 앉거나 누워 소리를 작게 맞춰 주세요.',
      '이어지는 빗소리와 가끔 들리는 천둥에 가볍게 귀를 기울여 보세요.',
      '무언가를 해내려 하지 않아도 괜찮아요. 편하게 숨 쉬며 잠시 쉬어보세요.',
    ],
  ),
  'busyMindRest': const SolutionGuide(
    title: '생각이 복잡한 날 · 3분 15초',
    icon: '💧',
    subtitle: '목소리 안내와 잔잔한 물소리',
    steps: [
      '편하게 앉아 등을 기대고 두 손을 편한 곳에 놓아주세요. 눈은 뜨고 있어도 괜찮아요.',
      '발바닥을 바닥에 가볍게 붙이고, 발이 바닥을 누르는 느낌을 살펴보세요.',
      '음악이나 주변의 작은 소리에 잠시 귀를 기울여보세요.',
      '생각이 떠오르면 억지로 멈추지 않아도 괜찮아요. 알아차렸다면 다시 소리를 들어보세요.',
      '턱과 어깨의 힘을 조금 풀고 평소처럼 숨 쉬며 쉬어보세요.',
      '마지막 안내에 따라 손발을 움직이고 주변을 둘러보세요. 준비가 되면 하던 일을 천천히 이어가세요.',
    ],
  ),
  'forestRest': const SolutionGuide(
    title: '숲에서 쉬는 2분',
    icon: '🌿',
    subtitle: '2분 · 목소리 안내와 잔잔한 새소리',
    steps: [
      '편하게 앉아 두 손을 무릎 위에 놓아주세요. 눈은 뜨고 있어도 괜찮아요.',
      '어깨를 가볍게 올렸다가 내려놓고, 턱의 힘도 조금 풀어주세요.',
      '숨은 평소처럼 편하게 쉬세요. 생각을 억지로 멈추지 않아도 괜찮아요.',
      '안내가 쉬는 동안 작은 새소리와 음악을 들으며 잠시 쉬어보세요.',
      '마지막 안내에 따라 손가락을 움직이고, 준비가 되면 하던 일로 돌아가세요.',
    ],
  ),
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
    title: '생각 구름 흘려보내기 · 7분',
    icon: '☁️',
    subtitle: '목소리 안내와 부드러운 기타 반주',
    steps: [
      '편하게 앉거나 누워주세요. 눈은 감거나 편한 곳을 바라봐도 괜찮아요.',
      '맑고 밝은 하늘과 천천히 움직이는 하얀 구름을 떠올려보세요.',
      '생각이 떠오르면 구름 하나에 할 일, 지난 일, 걱정처럼 짧은 이름을 붙여보세요.',
      '구름이 지나가는 모습을 바라보세요. 움직이지 않아도 억지로 밀어내지 않아도 괜찮아요.',
      '생각을 따라가고 있었다면 알아차리고 다시 하늘과 구름을 떠올려보세요.',
      '마지막 안내에 따라 손발을 움직여보세요. 누워 있었다면 준비가 되었을 때 천천히 일어나세요.',
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
    title: '감정 진정 호흡 · 4분 48초',
    icon: '🌊',
    subtitle: '목소리 안내와 부드러운 파도 소리',
    steps: [
      '편하게 앉거나 누워 두 손을 놓고 턱과 어깨의 힘을 조금 풀어주세요.',
      '평소처럼 숨 쉬며 공기가 들어오고 나가는 것을 느껴보세요.',
      '편하다면 내쉬는 숨을 조금 여유 있게 보내세요. 숨을 참거나 끝까지 내뱉으려고 하지 않아도 돼요.',
      '답답하거나 어지러우면 호흡 조절을 멈추고 평소처럼 쉬세요.',
      '속상한 생각이 떠오르면 억지로 밀어내지 않고 다음 숨을 느껴보세요.',
      '마지막 안내에 따라 주변을 살펴보고, 준비가 되면 천천히 움직이세요.',
    ],
  ),
  'sleepMeditation': const SolutionGuide(
    title: '잠들기 전, 하루를 내려놓기 · 7분 14초',
    icon: '🌙',
    subtitle: '목소리 안내와 작은 벽난로 소리',
    steps: [
      '편하게 눕거나 등을 기대고 앉아주세요. 이불과 베개를 편한 위치로 바꿔도 괜찮아요.',
      '턱과 어깨, 손가락의 힘을 조금 풀어주세요. 꼭 잠들려고 애쓰지 않아도 돼요.',
      '숨은 평소처럼 쉬세요. 호흡이 불편하면 이불이 닿는 느낌을 살펴보세요.',
      '오늘의 일이나 내일의 걱정이 떠오르면 내일 다시 살펴보자고 말하고 잠시 쉬어주세요.',
      '몸이 불편하면 언제든 자세를 바꿔도 좋아요. 지금 편해질 수 있는 만큼만 편하게 있어주세요.',
      '안내를 끝까지 듣지 않아도 괜찮아요. 졸음이 오면 그대로 잠들고, 잠이 오지 않아도 잠시 쉬어주세요.',
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
  '478Breathing': const SolutionGuide(
    title: '4-7-8 호흡법 · 구 영상',
    icon: '🌊',
    subtitle: '호흡 명상',
    steps: [
      '혀끝을 앞니 뒤 입천장에 살짝 대고 시작해보세요.',
      '4초 동안 코로 조용히 숨을 들이마셔요.',
      '7초 동안 숨을 참아요.',
      '8초 동안 "후~" 소리를 내며 입으로 길게 내쉬어요.',
      '영상의 구와 초 표시를 보며 4회 따라 해보세요. 준비와 마무리를 포함해 1분 28초입니다.',
      '답답하거나 어지러우면 멈추고 평소처럼 쉬세요.',
    ],
  ),
  'humBreathing': const SolutionGuide(
    title: '허밍 호흡 (콧노래 호흡)',
    icon: '🎵',
    subtitle: '호흡 명상',
    steps: [
      '편안히 앉아 코로 천천히 숨을 들이마셔요.',
      '숨을 내쉴 때 "음~" 소리를 내며 콧노래처럼 허밍해보세요.',
      '목과 가슴에 울리는 진동을 느껴보세요.',
      '이 허밍 호흡을 5~8회 반복하며 마음이 차분해지는 걸 느껴보세요.',
    ],
  ),
  'noteAwareness': const SolutionGuide(
    title: '지금 이 순간 알아차리기',
    icon: '📍',
    subtitle: '알아차림',
    steps: [
      '잠시 하던 일을 멈추고 지금 있는 자리를 느껴보세요.',
      '지금 몸이 어떤 자세로 있는지 알아차려보세요.',
      '지금 마음속에 어떤 감정이 있는지 이름을 붙여보세요 (예: "지금 나는 조금 지쳐있구나").',
      '판단하지 말고, 그저 "지금 이렇구나" 하고 알아차리는 것으로 충분해요.',
    ],
  ),
  'soundListening': const SolutionGuide(
    title: '소리 명상',
    icon: '🔔',
    subtitle: '알아차림',
    steps: [
      '눈을 감고 주변에서 들리는 소리에 귀 기울여보세요.',
      '가장 가까운 소리부터, 가장 먼 소리까지 차례로 찾아보세요.',
      '소리를 좋고 싫음으로 판단하지 말고 그저 소리 그대로 들어보세요.',
      '소리 사이에 있는 고요함도 함께 느껴보세요.',
      '1~2분 정도 이어가며 마음이 조금씩 가라앉는 걸 느껴보세요.',
    ],
  ),
  'shoulderRelease': const SolutionGuide(
    title: '어깨·목 스트레칭',
    icon: '🙆',
    subtitle: '움직이는 명상',
    steps: [
      '어깨를 귀 쪽으로 천천히 끌어올려보세요.',
      '3초간 멈춘 뒤, 숨을 내쉬며 툭 떨어뜨려보세요.',
      '고개를 오른쪽으로 천천히 기울여 목 옆쪽을 늘려보세요 (5초).',
      '반대쪽도 같은 방식으로 늘려보세요 (5초).',
      '어깨를 뒤로 5회, 앞으로 5회 천천히 돌려보세요.',
    ],
  ),
  'handStretch': const SolutionGuide(
    title: '손·손목 풀어주기',
    icon: '🤲',
    subtitle: '움직이는 명상',
    steps: [
      '양손을 앞으로 뻗고 손가락을 활짝 펼쳐보세요.',
      '손목을 천천히 시계 방향으로 5회 돌려보세요.',
      '반시계 방향으로도 5회 돌려보세요.',
      '두 손을 맞대고 꾹 눌러 손목 안쪽을 늘려보세요.',
      '마지막으로 손을 가볍게 털어 긴장을 흘려보내세요.',
    ],
  ),
  'letterToSelf': const SolutionGuide(
    title: '나에게 편지쓰기',
    icon: '💌',
    subtitle: '표현하기',
    steps: [
      '오늘의 나에게 짧은 편지를 써보세요.',
      '"오늘 너는 이런 걸 잘 견뎌냈어" 하고 시작해보세요.',
      '지금 힘든 점이 있다면 있는 그대로 적어보세요.',
      '마지막엔 "그래도 괜찮아, 나는 나를 응원해" 로 마무리해보세요.',
    ],
  ),
  'threeGoodThings': const SolutionGuide(
    title: '오늘의 좋았던 3가지',
    icon: '🍀',
    subtitle: '표현하기',
    steps: [
      '오늘 하루 중 작지만 좋았던 순간 3가지를 떠올려보세요.',
      '각 순간을 한 문장으로 적어보세요.',
      '그 순간이 왜 좋았는지 한 줄 덧붙여보세요.',
      '적은 문장을 소리 내어 읽어보며 다시 느껴보세요.',
    ],
  ),
  'safePlaceVisualization': const SolutionGuide(
    title: '안전한 장소 떠올리기',
    icon: '🏡',
    subtitle: '진정 · 이완',
    steps: [
      '눈을 감고 나만 알고 있는 편안한 장소를 떠올려보세요.',
      '그곳의 풍경, 냄새, 온도를 하나씩 상상해보세요.',
      '그곳에 있는 나 자신의 표정을 떠올려보세요.',
      '"나는 지금 안전하다"고 마음속으로 말해보세요.',
      '천천히 눈을 뜨며 그 편안함을 지금 이 순간으로 가져와보세요.',
    ],
  ),
  'anxietyContainer': const SolutionGuide(
    title: '불안 담아두기 상상법',
    icon: '📦',
    subtitle: '진정 · 이완',
    steps: [
      '지금 느껴지는 불안을 하나의 물건이라고 상상해보세요.',
      '마음속에 튼튼한 상자를 하나 떠올려보세요.',
      '그 불안을 상자 안에 조심스럽게 넣어보세요.',
      '상자 뚜껑을 닫고, "지금은 여기 잠시 놓아둘게" 라고 말해보세요.',
      '필요할 때 다시 열어볼 수 있다는 걸 기억하며 마음을 놓아보세요.',
    ],
  ),
  'napPrep': const SolutionGuide(
    title: '낮잠 전 짧은 이완',
    icon: '☁️',
    subtitle: '수면 명상',
    steps: [
      '눕거나 편안히 기대어 눈을 감아보세요.',
      '숨을 3번 천천히 들이마시고 내쉬어보세요.',
      '"지금은 잠깐 쉬어도 되는 시간"이라고 스스로에게 말해주세요.',
      '몸의 무게를 바닥에 맡기고 10분 정도 편히 쉬어보세요.',
    ],
  ),
  'morningGratitude': const SolutionGuide(
    title: '아침 감사 인사',
    icon: '🌤️',
    subtitle: '감사 명상',
    steps: [
      '눈을 뜨고 오늘 하루가 시작됨을 느껴보세요.',
      '오늘 만나게 될 사람이나 순간 중 기대되는 것 하나를 떠올려보세요.',
      '"오늘도 무사히 하루를 시작할 수 있어 감사하다" 고 마음속으로 말해보세요.',
      '가볍게 스트레칭하며 하루를 맞이해보세요.',
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

const List<SolutionCategory> _allSolutionCategories = [
  SolutionCategory(
    key: 'depressed',
    label: '우울할 때',
    icon: '🌧️',
    guideKeys: [
      'mindfulThought',
      'selfCompassion',
      'lovingKindness',
      'writing',
      'letterToSelf',
      'threeGoodThings',
    ],
  ),
  SolutionCategory(
    key: 'angry',
    label: '화날 때',
    icon: '🔥',
    guideKeys: [
      'angerCooling',
      'tensionRelease',
      'boxBreathing',
      '478Breathing',
      'anxietyContainer',
      'safePlaceVisualization',
    ],
  ),
  SolutionCategory(
    key: 'tired',
    label: '피곤할 때',
    icon: '🌙',
    guideKeys: [
      'forestRest',
      'fireplaceRest',
      'rainThunderRest',
      'singingBowlRest',
      'busyMindRest',
      'breathing',
      'bodyScan',
      'sleepMeditation',
      'deepRestMeditation',
      'napPrep',
      'humBreathing',
    ],
  ),
  SolutionCategory(
    key: 'lethargic',
    label: '무기력할 때',
    icon: '🫥',
    guideKeys: [
      'noteAwareness',
      'soundListening',
      'morningGratitude',
      'gratitudeExpansion',
      'grounding',
    ],
  ),
  SolutionCategory(
    key: 'movement',
    label: '기타 · 움직임 명상',
    icon: '🚶',
    guideKeys: [
      'taichi',
      'walkingMeditation',
      'stretching',
      'shoulderRelease',
      'handStretch',
    ],
  ),
];

/// 공개할 미디어가 준비된 가이드만 등록합니다. 원래 가이드와 분류는 보존합니다.
/// 새 오디오/영상을 에셋에 추가하고 이 목록에 키를 넣으면 공개됩니다.
const publishedMeditationKeys = <String>{
  'singingBowlRest',
  'forestRest',
  'busyMindRest',
  'mindfulThought',
  'angerCooling',
  'sleepMeditation',
  'rainThunderRest',
  'fireplaceRest',
  'breathing',
  '478Breathing',
};

List<String> publishedGuides(Iterable<String> keys) => keys
    .where(
      (key) =>
          publishedMeditationKeys.contains(key) &&
          breathingGuide.containsKey(key),
    )
    .toList(growable: false);

final List<SolutionCategory> solutionCategories = _allSolutionCategories
    .map(
      (category) => SolutionCategory(
        key: category.key,
        label: category.label,
        icon: category.icon,
        guideKeys: publishedGuides(category.guideKeys),
      ),
    )
    .where((category) => category.guideKeys.isNotEmpty)
    .toList(growable: false);

/// 카테고리 key로 [SolutionCategory]를 찾습니다.
SolutionCategory? solutionCategoryByKey(String key) {
  for (final c in solutionCategories) {
    if (c.key == key) return c;
  }
  return null;
}

/// 오늘 고른 감정 이모티콘([MoodPicker]에서 선택한 값)에 가장 잘 맞는 명상
/// 카테고리 key를 돌려줍니다. 맑음/설렘/행복처럼 이미 편안하거나 중립적인
/// 감정이라면 굳이 대처법을 추천하지 않고 null을 돌려줍니다.
String? solutionCategoryKeyForMood(String emoji) {
  switch (emoji) {
    case '🌧️': // 우울함
    case '😢': // 슬픔
      return 'depressed';
    case '🌪️': // 화남
      return 'angry';
    case '⛈️': // 힘듦
    case '❄️': // 지침
      return 'tired';
    case '😴': // 무기력
      return 'lethargic';
    default:
      return null;
  }
}

/// (하위 호환) 전체 카테고리 버튼 키 목록 - 기존 위젯 호환용
List<String> get solutionCategoryKeys =>
    solutionCategories.expand((c) => c.guideKeys).toList();

Map<String, String> get solutionCategoryLabels => {
  for (final key in solutionCategoryKeys) key: breathingGuide[key]!.title,
};
