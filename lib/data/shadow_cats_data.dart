import '../models/shadow_cat.dart';

/// 42마리 그림자 감정 고양이 (기존 36마리 + 신규 6마리: 수치심·억울함·허무함·
/// 감사·용기·유머)
/// - 고양이 선택(감정 체크인) 화면에서 오늘 내 기분과 닮은 고양이를 고를 때 사용
/// - 데일리 내면소통(카드뽑기) 화면에서도 동일한 42마리를 카드로 사용
final List<ShadowCat> shadowCats = [
  const ShadowCat(
    id: 'dreamy',
    nameKr: '몽상 고양이',
    nameEn: 'The Dreaming Cat',
    emoji: '💭',
    keyword: '몽상',
    imageAsset: 'assets/cards36/cat_01.png',
    story:
        '창가에 앉아 밤하늘 보름달을 가만히 올려다보는 이 고양이는 현실보다 상상 속에서 더 많은 시간을 보내요. '
        '하고 싶은 일과 되고 싶은 모습을 마음속으로 그리며, 언젠가는 그 꿈에 닿을 수 있을 거라 믿고 있답니다. '
        '다만 상상에 잠긴 나머지 가끔은 지금 이 순간을 놓치기도 해요.',
    meditationKeys: ['mindfulThought', 'grounding', 'bodyScan'],
    comfortMessage: '꿈꾸는 마음은 잘못이 아니에요. 오늘은 상상과 현실 사이에 다정한 다리를 놓아보세요.',
    guidance: '오늘 떠오른 상상 하나를 아주 작은 실천으로 바꿔보세요. 예: 하고 싶었던 일 1분만 시작해보기.',
  ),
  const ShadowCat(
    id: 'sad',
    nameKr: '슬픈 고양이',
    nameEn: 'The Sad Cat',
    emoji: '😢',
    keyword: '슬픔',
    imageAsset: 'assets/cards36/cat_02.png',
    story:
        '먹구름이 잔뜩 낀 하늘 아래, 이 고양이는 눈물을 글썽이며 조용히 서 있어요. 뭔가 잃어버린 것 같은 '
        '먹먹함이 가슴 한켠에 자리잡아, 이유 모를 눈물이 자꾸만 차오른답니다. 슬픔을 참지 않아도 괜찮다는 걸, '
        '이 고양이는 아직 잘 몰라요.',
    meditationKeys: ['selfCompassion', 'lovingKindness', 'writing'],
    comfortMessage: '슬퍼도 괜찮아요. 눈물은 마음이 스스로를 돌보는 방법이에요.',
    guidance: '오늘은 억지로 웃지 않아도 돼요. 슬픔을 잠시 그대로 느껴보세요.',
  ),
  const ShadowCat(
    id: 'jealous',
    nameKr: '질투하는 고양이',
    nameEn: 'The Jealous Cat',
    emoji: '😒',
    keyword: '질투',
    imageAsset: 'assets/cards36/cat_03.png',
    story:
        '흰 고양이가 맛있게 밥을 먹는 모습을 곁눈질하며, 이 고양이는 뾰로통한 표정을 감추지 못해요. "왜 나는 '
        '저렇게 될 수 없을까" 하는 생각에 마음이 조급해지고, 스스로가 작아지는 기분이 든답니다. 사실 그 안엔 '
        '자신도 인정받고 싶은 마음이 숨어 있어요.',
    meditationKeys: ['mindfulThought', 'writing', 'selfCompassion'],
    comfortMessage: '부러움은 내가 진짜 원하는 걸 알려주는 신호예요.',
    guidance: '부러웠던 것 하나를 적고, 그걸 갖기 위해 오늘 할 수 있는 작은 일을 찾아보세요.',
  ),
  const ShadowCat(
    id: 'angry',
    nameKr: '화난 고양이',
    nameEn: 'The Angry Cat',
    emoji: '😾',
    keyword: '분노',
    imageAsset: 'assets/cards36/cat_04.png',
    story:
        '뒤편에서 불길이 활활 타오르고, 이 고양이는 이빨을 드러내며 잔뜩 화가 나 있어요. 누군가 자신의 영역을 '
        '침범했거나 부당한 일을 당했을 때, 마음속에서 뜨거운 불이 확 타올랐답니다. 화를 억누르려 하지만 그 '
        '불씨는 몸 안에서 계속 들끓고 있어요.',
    meditationKeys: ['stretching', 'walkingMeditation', 'writing'],
    comfortMessage: '화는 나쁜 감정이 아니에요. 나를 지키려는 강한 목소리예요.',
    guidance: '몸을 크게 움직여 화를 밖으로 흘려보내 보세요. 스트레칭이나 걷기가 도움이 돼요.',
  ),
  const ShadowCat(
    id: 'proud',
    nameKr: '당당한 고양이',
    nameEn: 'The Proud Cat',
    emoji: '😌',
    keyword: '자신감',
    imageAsset: 'assets/cards36/cat_05.png',
    story:
        '아기자기한 다육식물 화분들 사이에 당당히 앉은 이 고양이는 스스로가 꽤 마음에 드는 눈치예요. 작은 '
        '성취도 크게 기뻐할 줄 알고, 자신을 있는 그대로 사랑하는 법을 알고 있답니다. 가끔은 그 자신감이 '
        '우쭐함으로 보일까 조심스럽기도 해요.',
    meditationKeys: ['lovingKindness', 'mindfulThought', 'writing'],
    comfortMessage: '당당함은 자랑이 아니라 자기 존중이에요. 오늘의 나를 인정해주세요.',
    guidance: '오늘 잘한 일 한 가지를 소리 내어 스스로에게 칭찬해보세요.',
  ),
  const ShadowCat(
    id: 'cautious',
    nameKr: '경계하는 고양이',
    nameEn: 'The Cautious Cat',
    emoji: '👀',
    keyword: '경계심',
    imageAsset: 'assets/cards36/cat_06.png',
    story:
        '초록 수풀 속에 몸을 숨긴 채, 이 고양이는 경계하는 눈빛으로 밖을 조심스레 내다봐요. 낯선 상황에 '
        '선뜻 나서기보다 먼저 안전을 확인하고 싶어 하는 신중한 성격이랍니다. 다만 너무 오래 숨어있다 보면 '
        '좋은 기회도 놓치게 될까 걱정이에요.',
    meditationKeys: ['grounding', 'breathing', 'bodyScan'],
    comfortMessage: '조심스러운 마음은 나를 지키는 지혜예요. 천천히 나와도 괜찮아요.',
    guidance: '오늘은 아주 작은 용기 한 걸음만 내딛어보세요.',
  ),
  const ShadowCat(
    id: 'weary',
    nameKr: '무기력한 고양이',
    nameEn: 'The Weary Cat',
    emoji: '😩',
    keyword: '무기력',
    imageAsset: 'assets/cards36/cat_07.png',
    story:
        '온몸을 바닥에 축 늘어뜨린 채, 이 고양이는 하루 종일 움직이지 않아요. 무엇을 해도 의미가 없게 느껴지고, '
        '좋아하던 것들에도 흥미가 사라진 지 오래됐답니다. 게으르다고 스스로를 탓하지만, 사실은 마음이 쉬어야 '
        '할 때라는 신호예요.',
    meditationKeys: ['taichi', 'stretching', 'walkingMeditation'],
    comfortMessage: '쉬어도 괜찮아요. 지금은 채찍질이 아니라 다정한 쉼이 필요한 때예요.',
    guidance: '오늘은 딱 한 가지, 아주 작은 움직임만 해보세요. 그걸로 충분해요.',
  ),
  const ShadowCat(
    id: 'anxious',
    nameKr: '불안한 고양이',
    nameEn: 'The Anxious Cat',
    emoji: '😰',
    keyword: '불안',
    imageAsset: 'assets/cards36/cat_08.png',
    story:
        '걱정 가득한 눈빛으로 앞발을 모아 입가에 댄 채, 이 고양이는 안절부절못하고 있어요. 아직 일어나지도 '
        '않은 일들을 미리 상상하며 불안해하고, 작은 소리에도 화들짝 놀란답니다. 사실 이 고양이는 그저 자신을 '
        '지키고 싶을 뿐이에요.',
    meditationKeys: ['breathing', 'boxBreathing', 'grounding'],
    comfortMessage: '불안은 위험을 미리 알려주려는 마음의 노력이에요. 지금은 안전해요.',
    guidance: '4-4-6 호흡을 세 번만 해보세요. 몸이 먼저 안정을 찾을 거예요.',
  ),
  const ShadowCat(
    id: 'lonely',
    nameKr: '외로운 고양이',
    nameEn: 'The Lonely Cat',
    emoji: '🥺',
    keyword: '외로움',
    imageAsset: 'assets/cards36/cat_09.png',
    story:
        '어두운 먹구름 아래, 이 고양이는 몸을 둥글게 웅크린 채 외로운 눈빛으로 정면을 바라봐요. 곁에 아무도 '
        '없다고 느껴질 때면 마음 한구석이 텅 빈 것처럼 시려온답니다. 다가가고 싶지만 상처받을까 두려워 조용히 '
        '거리를 두고 있어요.',
    meditationKeys: ['lovingKindness', 'selfCompassion', 'writing'],
    comfortMessage: '혼자인 것 같아도, 당신을 걱정하는 마음이 여기 있어요.',
    guidance: '오늘은 소중한 사람에게 짧은 안부 인사를 건네보세요.',
  ),
  const ShadowCat(
    id: 'confused',
    nameKr: '혼란스러운 고양이',
    nameEn: 'The Confused Cat',
    emoji: '❓',
    keyword: '혼란',
    imageAsset: 'assets/cards36/cat_10.png',
    story:
        '머리 위에 물음표를 띄운 채, 얼굴이 반반씩 검고 흰 이 고양이는 어리둥절한 표정을 짓고 있어요. 여러 '
        '선택지 앞에서 무엇이 옳은지 갈피를 못 잡고, 마음이 이랬다저랬다 흔들린답니다. 답을 서두르기보다 잠시 '
        '멈춰 생각할 시간이 필요해요.',
    meditationKeys: ['mindfulThought', 'grounding', 'writing'],
    comfortMessage: '지금 당장 답을 몰라도 괜찮아요. 혼란도 지나가는 과정이에요.',
    guidance: '고민을 종이에 적어보며 생각을 하나씩 정리해보세요.',
  ),
  const ShadowCat(
    id: 'nostalgic',
    nameKr: '그리운 고양이',
    nameEn: 'The Nostalgic Cat',
    emoji: '🌫️',
    keyword: '그리움',
    imageAsset: 'assets/cards36/cat_11.png',
    story:
        '뒤를 돌아보며 눈물을 흘리는 이 고양이는 지나간 시간을 자꾸 떠올려요. 좋았던 순간들이 그리워 마음이 '
        '아릿해지고, 다시는 돌아갈 수 없다는 사실에 서글퍼진답니다. 그리움은 그만큼 소중했다는 증거이기도 해요.',
    meditationKeys: ['writing', 'selfCompassion', 'lovingKindness'],
    comfortMessage: '그리움은 사랑했다는 증거예요. 그 마음을 부끄러워하지 않아도 돼요.',
    guidance: '그리운 순간을 짧게 글로 남겨 마음속에 고이 간직해보세요.',
  ),
  const ShadowCat(
    id: 'stubborn',
    nameKr: '고집스러운 고양이',
    nameEn: 'The Stubborn Cat',
    emoji: '😤',
    keyword: '고집',
    imageAsset: 'assets/cards36/cat_12.png',
    story:
        '화난 표정으로 꼬리를 치켜세운 채, 이 고양이는 씩씩하게 앞만 보고 걸어가요. 한번 마음먹은 건 좀처럼 '
        '바꾸지 않고, 남의 말보다 자기 확신을 믿는 편이랍니다. 가끔은 그 고집이 스스로를 더 힘들게 만들기도 해요.',
    meditationKeys: ['breathing', 'mindfulThought', 'stretching'],
    comfortMessage: '고집은 소신의 다른 이름이에요. 다만 가끔은 마음을 살짝 열어봐도 괜찮아요.',
    guidance: '오늘 한 가지 일에서만 다른 사람의 의견을 들어보세요.',
  ),
  const ShadowCat(
    id: 'vulnerable',
    nameKr: '다친 고양이',
    nameEn: 'The Wounded Cat',
    emoji: '🩹',
    keyword: '상처',
    imageAsset: 'assets/cards36/cat_13.png',
    story:
        '다리에 붕대를 감은 채, 꽃밭 한가운데서 이 고양이는 서럽게 울고 있어요. 마음이든 몸이든 어딘가 '
        '다쳐본 이는 알아요, 아무렇지 않은 척하는 게 얼마나 힘든지. 이 고양이에게는 낫기까지 기다려줄 시간과 '
        '다정한 보살핌이 필요해요.',
    meditationKeys: ['bodyScan', 'selfCompassion', 'lovingKindness'],
    comfortMessage: '상처는 약함이 아니라 애썼다는 흔적이에요. 천천히 나아가도 괜찮아요.',
    guidance: '오늘은 다친 마음에 밴드 하나 붙여주듯, 나를 다정하게 대해주세요.',
  ),
  const ShadowCat(
    id: 'indifferent',
    nameKr: '무심한 고양이',
    nameEn: 'The Indifferent Cat',
    emoji: '😐',
    keyword: '무심함',
    imageAsset: 'assets/cards36/cat_14.png',
    story:
        '두 발로 서서 무표정한 눈빛으로 정면을 응시하는 이 고양이는 좀처럼 감정을 드러내지 않아요. 무엇에도 '
        '크게 동요하지 않는 게 편할 때도 있지만, 가끔은 그 무심함 뒤로 진짜 감정을 숨기고 있는 건 아닌지 '
        '스스로도 헷갈린답니다.',
    meditationKeys: ['bodyScan', 'mindfulThought', 'writing'],
    comfortMessage: '무심해 보여도 괜찮아요. 감정을 느끼는 속도는 저마다 다르니까요.',
    guidance: '오늘 하루, 내 안에 어떤 감정이 있는지 딱 한 단어로 적어보세요.',
  ),
  const ShadowCat(
    id: 'impatient',
    nameKr: '조바심 나는 고양이',
    nameEn: 'The Impatient Cat',
    emoji: '⏳',
    keyword: '조바심',
    imageAsset: 'assets/cards36/cat_15.png',
    story:
        '굳게 닫힌 나무 문 앞에 덩그러니 앉아, 이 고양이는 안절부절못하며 문을 올려다봐요. 기다림이 길어질수록 '
        '마음이 조급해지고, 지금 당장 답을 알고 싶어 발을 동동 구른답니다. 하지만 어떤 문은 스스로 열릴 때까지 '
        '기다려야 해요.',
    meditationKeys: ['breathing', 'grounding', 'bodyScan'],
    comfortMessage: '기다림도 성장의 한 과정이에요. 문은 때가 되면 열려요.',
    guidance: '오늘은 기다리는 동안 할 수 있는 작은 일 하나를 찾아 해보세요.',
  ),
  const ShadowCat(
    id: 'needy',
    nameKr: '응석부리는 고양이',
    nameEn: 'The Needy Cat',
    emoji: '🥹',
    keyword: '애정결핍',
    imageAsset: 'assets/cards36/cat_16.png',
    story:
        '분홍빛 하트가 흩날리는 가운데, 이 고양이는 눈물을 글썽이며 두 앞발을 벌려 안아달라고 조르고 있어요. '
        '누군가의 관심과 애정이 없으면 마음이 자꾸 허전해지고, 사랑받고 있다는 확신이 필요하답니다. 그 마음을 '
        '부끄러워할 필요는 없어요.',
    meditationKeys: ['lovingKindness', 'selfCompassion', 'writing'],
    comfortMessage: '사랑받고 싶은 마음은 자연스러운 거예요. 먼저 나 자신을 안아주세요.',
    guidance: '거울 속의 나를 향해 오늘 하루도 애썼다고 말해주세요.',
  ),
  const ShadowCat(
    id: 'mischievous',
    nameKr: '장난꾸러기 고양이',
    nameEn: 'The Mischievous Cat',
    emoji: '😼',
    keyword: '장난기',
    imageAsset: 'assets/cards36/cat_17.png',
    story:
        '실을 매단 인형들을 손가락으로 조종하며, 이 고양이는 심술궂은 미소를 짓고 있어요. 규칙을 살짝 비틀고 '
        '예상 밖의 행동을 하는 게 왠지 짜릿하고 재미있답니다. 다만 그 장난이 가끔은 누군가를 곤란하게 만들기도 해요.',
    meditationKeys: ['writing', 'mindfulThought', 'walkingMeditation'],
    comfortMessage: '장난기는 삶에 활력을 더해줘요. 다만 그 웃음이 모두에게 즐겁길 바라요.',
    guidance: '오늘은 장난기를 좋은 곳에 써보세요. 누군가를 웃게 해주는 것으로요.',
  ),
  const ShadowCat(
    id: 'selfCritical',
    nameKr: '자책하는 고양이',
    nameEn: 'The Self-Critical Cat',
    emoji: '💔',
    keyword: '자책',
    imageAsset: 'assets/cards36/cat_18.png',
    story:
        '거울 속에 비친 울고 있는 자신의 모습을 바라보며, 이 고양이는 화가 난 듯 소리를 지르고 있어요. 실수를 '
        '하면 스스로를 심하게 몰아세우고, "왜 그것밖에 못했을까" 하며 자신을 탓한답니다. 하지만 그 누구보다 '
        '자신에게 가장 엄격한 건 바로 이 고양이 자신이에요.',
    meditationKeys: ['selfCompassion', 'lovingKindness', 'bodyScan'],
    comfortMessage: '실수해도 당신의 가치는 변하지 않아요. 스스로에게 조금 더 다정해도 돼요.',
    guidance: '오늘 나를 탓하고 싶을 때, 친한 친구에게 하듯 부드럽게 말해주세요.',
  ),
  const ShadowCat(
    id: 'grieving',
    nameKr: '눈물 고양이',
    nameEn: 'The Grieving Cat',
    emoji: '😭',
    keyword: '애도',
    imageAsset: 'assets/cards36/cat_19.png',
    story:
        '슬픈 눈망울로 눈물을 흘리며, 이 고양이는 바닥을 멍하니 바라보고 있어요. 소중했던 무언가를 떠나보낸 '
        '뒤, 마음 한켠이 자꾸만 시려온답니다. 슬픔을 서두르지 않고 충분히 흘려보내는 것도 애도의 한 방법이에요.',
    meditationKeys: ['selfCompassion', 'writing', 'lovingKindness'],
    comfortMessage: '이별의 아픔은 시간이 필요해요. 지금 이대로 슬퍼해도 괜찮아요.',
    guidance: '떠나보낸 것에게 짧은 편지를 써보며 마음을 정리해보세요.',
  ),
  const ShadowCat(
    id: 'hesitant',
    nameKr: '망설이는 고양이',
    nameEn: 'The Hesitant Cat',
    emoji: '🌉',
    keyword: '망설임',
    imageAsset: 'assets/cards36/cat_20.png',
    story:
        '부서진 나무 다리 앞에서 뒤를 돌아보며, 이 고양이는 경계하는 표정을 짓고 있어요. 앞으로 나아가야 할지, '
        '돌아가야 할지 쉽게 결정하지 못하고 망설이는 시간이 길어진답니다. 다리가 흔들려 보여도, 한 걸음씩 조심히 '
        '건너면 갈 수 있어요.',
    meditationKeys: ['grounding', 'breathing', 'mindfulThought'],
    comfortMessage: '망설임은 신중함의 다른 얼굴이에요. 준비가 되면 자연스레 나아가게 될 거예요.',
    guidance: '오늘은 망설이던 일 중 가장 작은 부분만 살짝 시작해보세요.',
  ),
  // 캐릭터 재배치: '놀란 고양이'는 그림자/황금그림자 어느 쪽에도 명확히
  // 속하지 않아 새 선택 목록에서는 보류(reserved)합니다. 원화·id는 그대로
  // 유지하여, 과거 이 캐릭터로 남은 기록은 계속 정상적으로 조회됩니다.
  const ShadowCat(
    id: 'surprised',
    nameKr: '놀란 고양이',
    nameEn: 'The Surprised Cat',
    emoji: '😳',
    keyword: '놀람',
    imageAsset: 'assets/cards36/cat_21.png',
    story:
        '얼음 조각 위에 서서 동그랗게 커진 눈으로, 이 고양이는 깜짝 놀란 표정을 짓고 있어요. 예상치 못한 일이 '
        '갑자기 벌어지면 마음이 철렁 내려앉고, 어떻게 반응해야 할지 몰라 얼어붙는답니다. 놀란 마음이 가라앉을 '
        '때까지 잠시 시간이 필요해요.',
    meditationKeys: ['breathing', 'grounding', 'bodyScan'],
    comfortMessage: '놀란 마음은 잠시 멈춰서 숨을 고르라는 신호예요.',
    guidance: '천천히 숨을 내쉬며 지금 발이 닿아있는 곳을 느껴보세요.',
    selectable: false,
  ),
  // 캐릭터 재배치: 기존 '잠든 고양이' 원화(웅크려 눈을 감고 늘어진 포즈)를
  // 그대로 살려 '피곤' 감정으로 재지정합니다. id·이미지는 변경하지 않고
  // 이름/설명/저널 안내만 새로 작성했습니다.
  const ShadowCat(
    id: 'sleepy',
    nameKr: '피곤한 고양이',
    nameEn: 'The Tired Cat',
    emoji: '😪',
    keyword: '피곤',
    imageAsset: 'assets/cards36/cat_22.png',
    story:
        '보라색 꽃송이를 지붕 삼아, 이 고양이는 몸을 잔뜩 웅크린 채 눈을 반쯤 내려감고 있어요. 힘든 걸 애써 '
        '누르고 티 내지 않으려 버텨온 하루였답니다. 겉으론 괜찮아 보이려 했지만, 사실은 쉬고 싶다는 말을 '
        '삼켜온 지 오래됐어요.',
    meditationKeys: ['deepRestMeditation', 'napPrep', 'bodyScan'],
    comfortMessage: '애써 버텨온 마음, 지금은 그만 내려놓아도 괜찮아요.',
    guidance: '오늘은 억지로 힘내지 말고, 잠깐이라도 눈을 감고 쉬어보세요.',
  ),
  const ShadowCat(
    id: 'sulky',
    nameKr: '삐친 고양이',
    nameEn: 'The Sulky Cat',
    emoji: '😤',
    keyword: '삐짐',
    imageAsset: 'assets/cards36/cat_23.png',
    story:
        '팔짱을 낀 채 뾰로통한 표정으로 곁눈질하는 이 고양이는 단단히 삐쳐있어요. 서운한 마음을 솔직히 말하기보다 '
        '토라진 티를 팍팍 내며 알아주기를 바란답니다. 사실 그 안엔 이해받고 싶은 마음이 가득해요.',
    meditationKeys: ['writing', 'mindfulThought', 'selfCompassion'],
    comfortMessage: '삐친 마음 뒤엔 서운함이 있어요. 그 마음을 알아주는 것만으로도 괜찮아요.',
    guidance: '서운했던 이유를 솔직하게 적어보고, 가능하다면 말로도 표현해보세요.',
  ),
  const ShadowCat(
    id: 'excluded',
    nameKr: '소외된 고양이',
    nameEn: 'The Excluded Cat',
    emoji: '🏝️',
    keyword: '소외감',
    imageAsset: 'assets/cards36/cat_24.png',
    story:
        '다른 고양이들이 어울려 노는 모습을 먼발치에서 바라보며, 이 고양이는 홀로 작은 섬에 쓸쓸히 앉아 있어요. '
        '무리에 끼지 못하는 것 같은 기분에 마음이 움츠러들고, 자신만 뒤처진 것 같아 속상하답니다. 하지만 함께할 '
        '곳은 반드시 있을 거예요.',
    meditationKeys: ['lovingKindness', 'selfCompassion', 'walkingMeditation'],
    comfortMessage: '지금 혼자처럼 느껴져도, 당신과 잘 맞는 자리가 분명 있어요.',
    guidance: '오늘은 나에게 편안한 사람 한 명에게 먼저 말을 걸어보세요.',
  ),
  const ShadowCat(
    id: 'joyful',
    nameKr: '행복한 고양이',
    nameEn: 'The Joyful Cat',
    emoji: '😸',
    keyword: '행복',
    imageAsset: 'assets/cards36/cat_25.png',
    story:
        '노란 꽃밭 속에 모여 앉아 서로 어깨를 맞대고, 이 고양이들은 환하게 웃으며 행복해하고 있어요. 함께 있는 '
        '것만으로도 마음이 따뜻해지고, 별것 아닌 순간에도 웃음이 끊이지 않는답니다. 이런 순간들이 삶을 든든하게 '
        '채워줘요.',
    meditationKeys: ['lovingKindness', 'walkingMeditation', 'writing'],
    comfortMessage: '지금 이 행복한 순간을 마음껏 누려도 괜찮아요.',
    guidance: '오늘의 행복한 순간을 사진이나 글로 남겨보세요.',
  ),
  const ShadowCat(
    id: 'affectionate',
    nameKr: '다정한 고양이',
    nameEn: 'The Affectionate Cat',
    emoji: '🥰',
    keyword: '다정함',
    imageAsset: 'assets/cards36/cat_26.png',
    story:
        '분홍빛 꽃길 사이에서 서로 볼을 비비며, 이 고양이들은 사랑스럽게 안겨 있어요. 마음을 나눌 상대가 곁에 '
        '있다는 것만으로도 큰 위안이 되고, 다정함을 주고받는 법을 잘 알고 있답니다. 그 온기가 하루를 든든하게 '
        '채워줘요.',
    meditationKeys: ['lovingKindness', 'writing', 'breathing'],
    comfortMessage: '다정함을 나눌 수 있는 오늘, 그 자체로 참 소중해요.',
    guidance: '가까운 사람에게 오늘 마음을 담아 작은 다정함을 표현해보세요.',
  ),
  // 캐릭터 재배치: '몰입하는 고양이'는 그림자/황금그림자 어느 쪽에도
  // 명확히 속하지 않아 새 선택 목록에서는 보류(reserved)합니다. 원화·id는
  // 그대로 유지하여, 과거 이 캐릭터로 남은 기록은 계속 정상적으로 조회됩니다.
  const ShadowCat(
    id: 'focused',
    nameKr: '몰입하는 고양이',
    nameEn: 'The Focused Cat',
    emoji: '✏️',
    keyword: '몰입',
    imageAsset: 'assets/cards36/cat_27.png',
    story:
        '커다란 연필을 손에 쥐고 진지한 표정으로 원을 그리는 이 고양이는 자신만의 영역을 만들어가는 중이에요. '
        '하나에 깊이 몰입할 때 시간 가는 줄 모르고, 완성해가는 과정 자체에서 큰 즐거움을 느낀답니다. 몰입은 이 '
        '고양이에게 가장 큰 활력소예요.',
    meditationKeys: ['mindfulThought', 'bodyScan', 'breathing'],
    comfortMessage: '몰입하는 순간, 당신은 가장 생생하게 살아있어요.',
    guidance: '오늘 몰입하고 싶은 일 하나에 방해 없이 20분만 집중해보세요.',
    selectable: false,
  ),
  const ShadowCat(
    id: 'excited',
    nameKr: '신나는 고양이',
    nameEn: 'The Excited Cat',
    emoji: '🤩',
    keyword: '신남',
    imageAsset: 'assets/cards36/cat_28.png',
    story:
        '꽃밭 위를 신나게 뛰어다니며, 이 고양이는 기쁨에 가득 차 활기찬 표정을 짓고 있어요. 좋은 일이 생기면 '
        '온몸으로 그 기쁨을 표현하고, 에너지가 넘쳐 가만히 있질 못한답니다. 이 활기가 주변에도 좋은 영향을 준다는 '
        '걸 이 고양이는 아직 잘 몰라요.',
    meditationKeys: ['walkingMeditation', 'taichi', 'writing'],
    comfortMessage: '신나는 마음, 마음껏 표현해도 괜찮아요. 그 에너지가 참 좋아요.',
    guidance: '오늘의 설렘을 몸을 움직이며 마음껏 발산해보세요.',
  ),
  const ShadowCat(
    id: 'curious',
    nameKr: '호기심 고양이',
    nameEn: 'The Curious Cat',
    emoji: '✨',
    keyword: '호기심',
    imageAsset: 'assets/cards36/cat_29.png',
    story:
        '반짝이는 별빛 눈망울로, 이 고양이는 호기심 가득하게 무언가를 바라보고 있어요. 새로운 것을 발견하면 '
        '눈이 반짝이고, "이건 뭘까?" 하는 궁금증이 끊이지 않는답니다. 그 호기심이 이 고양이를 더 넓은 세상으로 '
        '이끌어줘요.',
    meditationKeys: ['mindfulThought', 'walkingMeditation', 'writing'],
    comfortMessage: '궁금한 게 많다는 건 마음이 아직 활짝 열려있다는 뜻이에요.',
    guidance: '오늘 궁금했던 것 하나를 직접 찾아보거나 시도해보세요.',
  ),
  const ShadowCat(
    id: 'comforted',
    nameKr: '포근한 고양이',
    nameEn: 'The Comforted Cat',
    emoji: '🤗',
    keyword: '포근함',
    imageAsset: 'assets/cards36/cat_30.png',
    story:
        '서로를 따뜻하게 껴안으며, 이 고양이들은 애정 가득한 눈빛과 미소를 나누고 있어요. 힘든 하루 끝에 서로에게 '
        '기댈 수 있다는 것이 얼마나 큰 위로가 되는지 잘 알고 있답니다. 포근한 품이 있다는 것만으로 마음이 놓여요.',
    meditationKeys: ['bodyScan', 'lovingKindness', 'breathing'],
    comfortMessage: '지금 느끼는 포근함을 마음껏 느껴보세요. 당신은 안전해요.',
    guidance: '오늘은 나를 편안하게 해주는 것 곁에 잠시 머물러보세요.',
  ),
  const ShadowCat(
    id: 'playful',
    nameKr: '놀고 싶은 고양이',
    nameEn: 'The Playful Cat',
    emoji: '🧶',
    keyword: '놀이',
    imageAsset: 'assets/cards36/cat_31.png',
    story:
        '알록달록한 털실 뭉치를 가지고, 이 고양이는 신나게 뒹굴며 놀고 있어요. 재미있는 것 앞에서는 시간 가는 '
        '줄 모르고 몰두하고, 노는 것 자체가 삶의 활력소랍니다. 가끔은 어른스러워지려 애쓰기보다 이렇게 놀아도 '
        '괜찮아요.',
    meditationKeys: ['walkingMeditation', 'writing', 'taichi'],
    comfortMessage: '노는 것도 마음을 돌보는 훌륭한 방법이에요.',
    guidance: '오늘은 잠시라도 아무 목적 없이 순수하게 즐거운 일을 해보세요.',
  ),
  // 캐릭터 재배치: 기존 '몽환적인 고양이' 원화(흐릿한 시선, 몽롱한 톤)를
  // 그대로 살려 '모르겠어' 감정으로 재지정합니다. id·이미지는 변경하지
  // 않고 이름/설명/저널 안내만 새로 작성했습니다. 억압이 아니라, 아직
  // 감정이 무엇인지 분화되지 않은 상태를 나타냅니다.
  const ShadowCat(
    id: 'enchanted',
    nameKr: '모르겠는 고양이',
    nameEn: 'The Not-Sure Cat',
    emoji: '💭',
    keyword: '모르겠어',
    imageAsset: 'assets/cards36/cat_32.png',
    story:
        '아름다운 푸른 꽃 아치 아래에서, 이 고양이는 나비들을 물끄러미 올려다보고 있어요. 시선은 또렷하지 않고 '
        '표정도 흐릿한 채로, 지금 이 마음이 슬픔인지 반가움인지 조차 스스로도 알기 어렵답니다. 굳이 이름 붙이려 '
        '애쓰지 않아도, 그저 이런 상태로 잠시 머물러도 괜찮아요.',
    meditationKeys: ['mindfulThought', 'noteAwareness', 'grounding'],
    comfortMessage: '지금 무슨 감정인지 몰라도 괜찮아요. 억누른 게 아니라, 아직 알아가는 중일 뿐이에요.',
    guidance: '오늘은 감정에 이름을 붙이려 하지 말고, 그냥 있는 그대로 가만히 느껴보세요.',
  ),
  const ShadowCat(
    id: 'serene',
    nameKr: '평온한 고양이',
    nameEn: 'The Serene Cat',
    emoji: '🌙',
    keyword: '평온',
    imageAsset: 'assets/cards36/cat_33.png',
    story:
        '은은하게 빛나는 초승달 앞에서 눈을 지긋이 감은 채, 이 고양이는 평온하게 휴식을 취하고 있어요. 소란스러운 '
        '마음이 잦아들고 고요함이 찾아온 이 순간, 무엇에도 흔들리지 않는 편안함을 느낀답니다. 평온함은 애써 만드는 '
        '게 아니라 그저 머무는 거예요.',
    meditationKeys: ['breathing', 'bodyScan', 'taichi'],
    comfortMessage: '지금 이 평온함을 충분히 느껴보세요. 참 잘 지내고 있어요.',
    guidance: '오늘 하루 5분만 아무것도 하지 않고 고요히 앉아보세요.',
  ),
  const ShadowCat(
    id: 'studious',
    nameKr: '지적인 고양이',
    nameEn: 'The Studious Cat',
    emoji: '📚',
    keyword: '탐구',
    imageAsset: 'assets/cards36/cat_34.png',
    story:
        '책더미 위에 의젓하게 앉아 안경을 쓴 채, 이 고양이는 지적인 분위기를 풍기고 있어요. 새로운 지식을 배우고 '
        '이해하는 과정 자체를 즐기고, 궁금한 것을 끝까지 파고드는 성실함을 지녔답니다. 배움은 이 고양이에게 삶의 '
        '중요한 즐거움이에요.',
    meditationKeys: ['mindfulThought', 'writing', 'breathing'],
    comfortMessage: '배우고 성장하려는 그 마음이 참 멋져요.',
    guidance: '오늘 궁금했던 것 하나를 짧게라도 찾아보고 배워보세요.',
  ),
  const ShadowCat(
    id: 'protective',
    nameKr: '보호하는 고양이',
    nameEn: 'The Protective Cat',
    emoji: '🛡️',
    keyword: '보호본능',
    imageAsset: 'assets/cards36/cat_35.png',
    story:
        '아기 고양이 두 마리를 품에 꼭 안은 채, 이 고양이는 따뜻한 보호 본능을 드러내고 있어요. 소중한 존재를 '
        '지키기 위해서라면 무엇이든 감수할 준비가 되어 있고, 그 책임감이 마음을 든든하게 채워준답니다. 다만 '
        '가끔은 자신을 돌보는 것도 잊지 말아야 해요.',
    meditationKeys: ['lovingKindness', 'bodyScan', 'breathing'],
    comfortMessage: '누군가를 지키는 그 마음, 참 다정하고 강해요. 스스로도 잊지 말고 돌봐주세요.',
    guidance: '오늘은 소중한 존재를 돌보는 만큼, 나 자신도 살짝 돌봐주세요.',
  ),
  const ShadowCat(
    id: 'content',
    nameKr: '만족한 고양이',
    nameEn: 'The Content Cat',
    emoji: '🌈',
    keyword: '만족',
    imageAsset: 'assets/cards36/cat_36.png',
    story:
        '무지개와 달빛 아래, 이 고양이들은 단란하게 함께 앉아 고요하고 만족스러운 시간을 보내고 있어요. 특별한 '
        '일이 없어도 지금 이 순간에 감사할 줄 알고, 있는 그대로의 하루에 편안함을 느낀답니다. 만족은 큰 것에서 '
        '오지 않는다는 걸 이 고양이는 잘 알아요.',
    meditationKeys: ['lovingKindness', 'bodyScan', 'writing'],
    comfortMessage: '지금 이대로도 충분해요. 오늘 하루에 감사한 마음을 가져보세요.',
    guidance: '오늘 감사했던 순간 세 가지를 떠올려보세요.',
  ),
  // 신규 6마리 추가: 수치심·억울함·허무함·감사·용기·유머
  // 각각 기존 캐릭터와 혼동되기 쉬운 감정을 명확히 구분하기 위해 자세와
  // 표정, 색감을 세밀하게 다르게 그렸습니다.
  const ShadowCat(
    id: 'ashamed',
    nameKr: '수치스러운 고양이',
    nameEn: 'The Ashamed Cat',
    emoji: '🙈',
    keyword: '수치심',
    imageAsset: 'assets/cards36/cat_37.png',
    story:
        '몸을 살짝 웅크리고 시선을 피한 채, 이 고양이는 자꾸 작아지고 있어요. 무언가를 잘못해서가 아니라, '
        '그냥 "나 자신이 충분하지 않다"는 낯선 감각이 마음 깊은 곳에서 스며든답니다. 잘못을 따지기보다, '
        '존재 자체가 조용히 옅어지는 것 같은 기분이에요.',
    meditationKeys: ['selfCompassion', 'lovingKindness', 'bodyScan'],
    comfortMessage: '당신이 부족해서가 아니에요. 지금 그 마음은 지나가는 그림자일 뿐, 존재 자체는 흐려지지 않아요.',
    guidance: '오늘은 잘못을 찾기보다, 그냥 "나는 지금 여기 있어도 돼"라고 조용히 말해보세요.',
  ),
  const ShadowCat(
    id: 'wronged',
    nameKr: '억울한 고양이',
    nameEn: 'The Wronged Cat',
    emoji: '😦',
    keyword: '억울함',
    imageAsset: 'assets/cards36/cat_38.png',
    story:
        '두 눈을 크게 뜨고 입을 꾹 다문 채, 이 고양이는 하고 싶은 말을 삼키며 가만히 서 있어요. 화를 내며 '
        '달려들기보다, 억울한 마음을 안으로 꾹꾹 눌러 참고 견디는 쪽이랍니다. 아무도 몰라줄까 봐, 숨이 막힐 '
        '듯 답답한 기분이 가슴에 고여 있어요.',
    meditationKeys: ['writing', 'tensionRelease', 'breathing'],
    comfortMessage: '말하지 못한 그 마음, 무시당한 게 아니에요. 지금이라도 당신의 목소리를 들어줄 사람이 필요해요.',
    guidance: '삼켰던 말을 종이에 그대로 옮겨 적어보세요. 누구에게도 보여주지 않아도 괜찮아요.',
  ),
  const ShadowCat(
    id: 'hollow',
    nameKr: '허무한 고양이',
    nameEn: 'The Hollow Cat',
    emoji: '🕳️',
    keyword: '허무함',
    imageAsset: 'assets/cards36/cat_39.png',
    story:
        '먼 곳을 멍하니 바라보며, 이 고양이는 몸에 힘을 하나도 주지 않고 늘어져 있어요. 기운이 없어서가 '
        '아니라, 무엇을 해도 다 무슨 의미인지 흐릿해져 버린 것 같은 기분이랍니다. 눈앞의 것들이 초점 없이 '
        '뭉개져 보이고, "왜"라는 질문조차 희미해진 순간이에요.',
    meditationKeys: ['mindfulThought', 'grounding', 'noteAwareness'],
    comfortMessage: '의미가 안 보인다고 당신이 잘못된 게 아니에요. 가끔은 의미를 찾지 않고 그냥 흘러가도 괜찮아요.',
    guidance: '오늘은 답을 찾으려 하지 말고, 눈에 보이는 것 하나를 가만히 오래 바라보세요.',
  ),
  const ShadowCat(
    id: 'grateful',
    nameKr: '감사하는 고양이',
    nameEn: 'The Grateful Cat',
    emoji: '🙏',
    keyword: '감사',
    imageAsset: 'assets/cards36/cat_40.png',
    story:
        '두 앞발을 가만히 모으고 눈을 살짝 감은 채, 이 고양이는 조용히 미소 짓고 있어요. 화려하게 표현하지 '
        '않아도, 오늘 있었던 작은 것들에 마음이 따뜻해진답니다. 소란스럽지 않은 이 잔잔한 기쁨이, 하루를 '
        '은은하게 채워줘요.',
    meditationKeys: [
      'gratitudeExpansion',
      'morningGratitude',
      'threeGoodThings',
    ],
    comfortMessage: '감사는 크게 소리치지 않아도 충분해요. 지금 그 조용한 따뜻함을 그대로 느껴보세요.',
    guidance: '오늘 고마웠던 아주 작은 것 하나를 마음속으로 가만히 되새겨보세요.',
  ),
  const ShadowCat(
    id: 'courageous',
    nameKr: '용기내는 고양이',
    nameEn: 'The Courageous Cat',
    emoji: '🐯',
    keyword: '용기',
    imageAsset: 'assets/cards36/cat_41.png',
    story:
        '정면을 똑바로 바라보며, 이 고양이는 다리에 살짝 힘을 준 채 한 걸음을 내딛고 있어요. 두렵지 않은 게 '
        '아니라, 두려움을 안고도 앞으로 나아가기로 마음먹은 긴장감이 몸 전체에 흐른답니다. 여유롭게 자신하는 '
        '것과는 달리, 지금은 온몸으로 그 순간을 버티고 있어요.',
    meditationKeys: ['breathing', 'grounding', 'walkingMeditation'],
    comfortMessage: '떨리면서도 나아가는 것, 그게 진짜 용기예요. 두려움이 있어도 당신은 이미 앞으로 가고 있어요.',
    guidance: '오늘 미뤄왔던 일 중 가장 무서운 한 걸음을 아주 작게라도 내딛어보세요.',
  ),
  const ShadowCat(
    id: 'witty',
    nameKr: '유머러스한 고양이',
    nameEn: 'The Witty Cat',
    emoji: '😏',
    keyword: '유머',
    imageAsset: 'assets/cards36/cat_42.png',
    story:
        '몸은 미동도 없이 가만히 앉은 채, 이 고양이는 한쪽 눈을 슬쩍 감으며 장난스러운 미소를 짓고 있어요. '
        '뛰어다니거나 소란을 피우지 않아도, 눈빛과 표정 하나로 충분히 웃음을 자아낸답니다. 가만히 있는 몸과 '
        '생생하게 살아있는 표정의 대비가, 이 고양이만의 매력이에요.',
    meditationKeys: ['threeGoodThings', 'writing', 'mindfulThought'],
    comfortMessage: '가만히 있어도 재치는 빛나요. 오늘의 유머, 그 자체로 충분히 근사해요.',
    guidance: '오늘 무거운 순간이 오면, 딱 한 마디의 가벼운 농담을 떠올려보세요.',
  ),
  // ── 유료(Basic 구독) 10마리 ──
  // 무료 42마리와 혼동되기 쉬운 감정들을 더 섬세하게 세분화한 캐릭터들입니다.
  // isPremium: true로 표시되며, 감정체크 화면에서는 항상 노출되지만
  // '안개' 처리로 흐리게 보이고, 탭하면 가장 가까운 무료 캐릭터를 먼저
  // 안내합니다(alternative_emotion_mapping.dart 참조).
  const ShadowCat(
    id: 'cynical',
    nameKr: '냉소적인 고양이',
    nameEn: 'The Cynical Cat',
    emoji: '😏',
    keyword: '냉소',
    imageAsset: 'assets/cards36/cat_43.png',
    story:
        '한쪽 입꼬리를 슬쩍 올리며, 이 고양이는 흘러가는 풍경을 시큰둥하게 바라보고 있어요. 무심해서가 '
        '아니라, "어차피 다 그런 거지" 하는 씁쓸한 체념이 마음 한켠에 자리 잡은 거예요. 무엇에도 크게 '
        '기대하지 않게 된 지금이, 스스로도 조금은 낯설게 느껴진답니다.',
    meditationKeys: ['mindfulThought', 'writing', 'noteAwareness'],
    comfortMessage: '냉소는 상처받지 않으려는 나름의 방식이었을 거예요. 그 마음도 이해받을 자격이 있어요.',
    guidance: '오늘은 시큰둥해지기 전에, 그 뒤에 숨은 진짜 기대를 한 번 들여다보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'envious',
    nameKr: '시기하는 고양이',
    nameEn: 'The Envious Cat',
    emoji: '👀',
    keyword: '시기',
    imageAsset: 'assets/cards36/cat_44.png',
    story:
        '몸을 앞으로 쭉 내밀고, 이 고양이는 저 멀리 다른 고양이를 매섭게 쳐다보고 있어요. 부러움을 안으로 '
        '삭이기보다, 그 대상에게서 시선을 떼지 못하고 자꾸만 비교하게 된답니다. "왜 나는 저렇게 안 될까" '
        '하는 생각이 자꾸만 마음을 콕콕 찌르는 것 같아요.',
    meditationKeys: ['selfCompassion', 'writing', 'gratitudeExpansion'],
    comfortMessage: '누군가를 자꾸 바라보게 되는 건, 당신 안에도 같은 걸 원하는 마음이 있다는 뜻이에요.',
    guidance: '오늘은 그 사람에게서 눈을 돌려, 내가 이미 가진 것 하나를 적어보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'hurtFeelings',
    nameKr: '서운한 고양이',
    nameEn: 'The Hurt Cat',
    emoji: '🥺',
    keyword: '서운함',
    imageAsset: 'assets/cards36/cat_45.png',
    story:
        '몸을 돌린 채 어깨너머로 살짝 돌아보며, 이 고양이는 눈가에 눈물을 그렁그렁 매달고 있어요. 크게 '
        '소리 내어 울 만큼 슬픈 건 아니지만, "나를 잊었나봐" 하는 서운함이 조용히 마음에 고인답니다. '
        '말하면 유치해 보일까 봐, 그냥 삼키고 돌아서는 쪽을 택하는 거예요.',
    meditationKeys: ['writing', 'selfCompassion', 'breathing'],
    comfortMessage: '서운함을 느끼는 건 그만큼 마음을 썼다는 뜻이에요. 그 마음, 작지 않아요.',
    guidance: '오늘은 서운했던 순간을 한 문장으로 적어, 스스로에게만 솔직히 인정해주세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'inferior',
    nameKr: '열등감 느끼는 고양이',
    nameEn: 'The Cat Feeling Inferior',
    emoji: '😞',
    keyword: '열등감',
    imageAsset: 'assets/cards36/cat_46.png',
    story:
        '몸을 작게 웅크리고 고개를 푹 숙인 채, 이 고양이는 자기 자신이 한없이 작아 보인다고 느껴요. '
        '누군가와 다투거나 한 번 부러웠던 순간이 아니라, "나는 원래부터 부족한 존재인가봐" 하는 오래된 '
        '무게가 등 뒤에 크게 그림자처럼 걸려 있는 듯한 기분이에요.',
    meditationKeys: ['selfCompassion', 'lovingKindness', 'gratitudeExpansion'],
    comfortMessage: '누군가와 비교해서 매겨진 값이 당신의 전부는 아니에요. 당신은 이미 고유해요.',
    guidance: '오늘은 남과 비교하지 않고, 오직 나만이 가진 장점 하나를 떠올려보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'dread',
    nameKr: '두려운 고양이',
    nameEn: 'The Fearful Cat',
    emoji: '😰',
    keyword: '두려움',
    imageAsset: 'assets/cards36/cat_47.png',
    story:
        '몸을 바짝 낮추고 얼어붙은 채, 이 고양이는 눈을 커다랗게 뜨고 꼼짝도 못 하고 있어요. 그저 조금 '
        '불안한 정도가 아니라, 지금 당장 무언가 위협적인 일이 닥칠 것 같은 강렬한 공포가 온몸을 덮친 '
        '거예요. 숨조차 조심스럽게 쉬어야 할 것 같은, 그런 긴박한 순간이랍니다.',
    meditationKeys: ['breathing', 'grounding', 'bodyScan'],
    comfortMessage: '두려움이 이렇게 크다는 건, 지금 당신에게 안전함이 꼭 필요하다는 신호예요.',
    guidance: '오늘은 발이 닿은 자리를 꾹꾹 눌러보며, 지금 여기가 안전하다는 걸 몸으로 확인해보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'guilty',
    nameKr: '죄책감 느끼는 고양이',
    nameEn: 'The Guilty Cat',
    emoji: '🙏',
    keyword: '죄책감',
    imageAsset: 'assets/cards36/cat_48.png',
    story:
        '앞발을 가슴에 얹고 고개를 숙인 채, 이 고양이는 걱정스러운 눈빛으로 위를 슬쩍 올려다보고 있어요. '
        '자신을 몰아세우기보다, "그때 그 말은 하지 말았어야 했는데" 하며 누군가에게 미안한 마음이 자꾸 '
        '떠오른답니다. 잘못을 바로잡고 다시 다가가고 싶은, 관계를 향한 마음이에요.',
    meditationKeys: ['writing', 'selfCompassion', 'lovingKindness'],
    comfortMessage: '미안한 마음이 든다는 건, 그 관계를 소중히 여긴다는 뜻이에요. 진심을 전할 기회는 아직 있어요.',
    guidance: '오늘은 미안했던 마음을 짧게라도 그 사람에게 전해보는 걸 생각해보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'openHearted',
    nameKr: '취약함을 인정하는 고양이',
    nameEn: 'The Cat Acknowledging Vulnerability',
    emoji: '💗',
    keyword: '취약함 인정',
    imageAsset: 'assets/cards36/cat_49.png',
    story:
        '두 앞발을 활짝 펴 보이며, 이 고양이는 가슴을 열고 담담하게 정면을 바라보고 있어요. 숨기지 않고 '
        '"나 지금 힘들어"라고 솔직히 말하는 건 약한 게 아니라, 오히려 스스로를 있는 그대로 보여줄 수 있는 '
        '용기랍니다. 다친 곳을 감추는 게 아니라, 여린 마음을 그대로 내보이는 거예요.',
    meditationKeys: ['selfCompassion', 'writing', 'lovingKindness'],
    comfortMessage: '약함을 인정하는 건 용기예요. 그 솔직함이 결국 더 깊은 연결을 만들어줘요.',
    guidance: '오늘은 가까운 사람에게 지금 느끼는 그대로의 마음을 솔직히 한마디 건네보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'creative',
    nameKr: '창의적인 고양이',
    nameEn: 'The Creative Cat',
    emoji: '💡',
    keyword: '창의성',
    imageAsset: 'assets/cards36/cat_50.png',
    story:
        '한쪽 앞발을 번쩍 들어 올리며, 이 고양이는 방금 떠오른 반짝이는 생각에 눈을 크게 빛내고 있어요. '
        '단순히 신기한 것을 구경하는 게 아니라, 머릿속에서 새로운 무언가를 직접 그려내고 만들어내고 싶은 '
        '충동이 몸 전체에서 뿜어져 나온답니다. 이 순간의 설렘은 무엇이든 될 수 있어요.',
    meditationKeys: ['writing', 'mindfulThought', 'threeGoodThings'],
    comfortMessage: '떠오른 그 반짝임은 소중해요. 완벽하지 않아도 일단 시작해보는 것부터가 창조예요.',
    guidance: '오늘 떠오른 아이디어 하나를, 작더라도 실제로 손으로 옮겨보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'leaderly',
    nameKr: '리더십 있는 고양이',
    nameEn: 'The Leader Cat',
    emoji: '🧭',
    keyword: '리더십',
    imageAsset: 'assets/cards36/cat_51.png',
    story:
        '가슴을 펴고 한 발 앞서 걸어가며, 이 고양이는 뒤따르는 이들을 자연스럽게 이끌고 있어요. 스스로를 '
        '자랑하기 위해서가 아니라, "내가 먼저 가볼게, 같이 가자"는 든든한 마음으로 앞장서는 거예요. 다른 '
        '이들을 살피고 방향을 잡아주는 책임감이 몸에 은은하게 흐른답니다.',
    meditationKeys: ['walkingMeditation', 'mindfulThought', 'breathing'],
    comfortMessage: '앞서 나서는 마음은 곧 누군가를 향한 책임감이에요. 그 든든함이 사람들을 안심시켜요.',
    guidance: '오늘은 누군가를 위해 먼저 한 걸음 나서서 방향을 제안해보세요.',
    isPremium: true,
  ),
  const ShadowCat(
    id: 'convicted',
    nameKr: '확신에 찬 고양이',
    nameEn: 'The Cat with Conviction',
    emoji: '⭐',
    keyword: '확신',
    imageAsset: 'assets/cards36/cat_52.png',
    story:
        '허리를 곧게 펴고 앞발을 가만히 모은 채, 이 고양이는 흔들림 없이 정면을 바라보고 있어요. 무언가를 '
        '이뤄서 뿌듯한 것도, 그저 나른하게 만족한 것도 아니라, "나는 내가 믿는 걸 알아"라는 조용하고 굳건한 '
        '중심이 가슴 한가운데 자리 잡은 느낌이에요. 크게 소리치지 않아도 단단해요.',
    meditationKeys: ['grounding', 'mindfulThought', 'breathing'],
    comfortMessage: '확신은 시끄럽지 않아도 돼요. 지금 당신 안의 그 고요한 중심을 믿어보세요.',
    guidance: '오늘 내가 믿는 것 하나를 마음속으로 조용히, 그러나 또렷하게 되새겨보세요.',
    isPremium: true,
  ),
];

ShadowCat shadowCatById(String id) => shadowCats.firstWhere((c) => c.id == id);

/// 무료로 제공되는 그림자 고양이 목록(정확히 42마리). 유료(Basic 구독)
/// 캐릭터 10마리는 제외됩니다.
///
/// ⚠️ [shadowCats.length]는 무료+유료를 합친 52마리를 반환하므로, "42마리"를
/// 목표/기준으로 안내하는 화면(졸업 앨범, 만난 고양이 수 등)에서는 절대
/// [shadowCats.length] 대신 이 [freeShadowCats.length]를 사용해야 합니다.
/// (유료 캐릭터는 구독하지 않으면 반려묘로 육성할 수 없어, 52를 목표로
/// 잡으면 영원히 채울 수 없는 목표가 되어버립니다.)
final List<ShadowCat> freeShadowCats = shadowCats
    .where((c) => !c.isPremium)
    .toList();
