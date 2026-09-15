import 'mongi_garden_data.dart';

enum GardenMomentTrigger { welcome, cat, run, plant, letter, meditation }

class GardenMoment {
  final GardenMomentTrigger trigger;
  final String title, condition, body;
  const GardenMoment(this.trigger, this.title, this.condition, this.body);
  bool isAvailable(MongiGardenData data, int cats) => switch (trigger) {
    GardenMomentTrigger.welcome => true,
    GardenMomentTrigger.letter => data.recordDays.isNotEmpty,
    GardenMomentTrigger.meditation => data.meditationDays.isNotEmpty,
    GardenMomentTrigger.cat => cats > 0,
    GardenMomentTrigger.run => data.stage >= 2,
    GardenMomentTrigger.plant => data.seeds.values.any((count) => count > 0),
  };
}

const gardenMoments = [
  GardenMoment(
    GardenMomentTrigger.welcome,
    '돌아올 곳',
    '처음부터 읽을 수 있어요',
    '''몽이는 정원 문을 밀었다. 경첩이 작게 울렸다. 아직 발자국이 없는 흙길 끝에 햇빛이 길게 누워 있었다.

몽이는 문 옆의 납작한 돌을 옮겨 문이 닫히지 않게 받쳤다. 바람이 지나가도 문은 조금 열린 채였다.

한 바퀴 달리고 돌아오면 어디에 앉을까. 몽이는 이곳저곳을 살피다 문 가까운 풀밭에 몸을 내려놓았다. 멀리서 잎사귀 하나가 굴러왔다. 앞발을 뻗었다가, 그대로 지나가게 두었다.

문 너머의 길과 정원 안의 길이 오후 내내 이어져 있었다.''',
  ),
  GardenMoment(
    GardenMomentTrigger.cat,
    '나란히 놓인 그릇',
    '고양이 한 마리를 만나면 열려요',
    '''풀밭에 먼저 앉아 있던 고양이가 고개를 들었다. 몽이는 두어 걸음 앞에서 멈췄다. 인사를 하려는데 고양이가 하품을 하는 바람에, 몽이도 입을 크게 벌리고 말았다.

몽이는 물그릇을 가져다 놓았다. 너무 가까운가 싶어 조금 밀고, 너무 먼가 싶어 다시 당겼다. 고양이는 그릇보다 몽이의 분주한 앞발을 오래 바라보았다.

잠시 뒤 물을 마시는 작은 소리가 났다. 몽이는 자기 그릇도 옆에 놓았다. 두 그릇에 같은 구름이 비쳤다.

둘은 구름이 지나갈 때까지 그 자리에 앉아 있었다.''',
  ),
  GardenMoment(
    GardenMomentTrigger.run,
    '문 앞에서 고르는 숨',
    '몽이 2단계에 도착하면 열려요',
    '''길을 달리고 돌아온 몽이의 앞발에 흙이 묻어 있었다. 가슴에는 길에서 받아 안은 빛이 조금 남아 있었다. 문 옆에 앉은 고양이가 귀를 세웠다.

몽이는 오늘 만난 것들을 말하려다가 먼저 숨을 골랐다. 고양이는 기다리는 동안 제 꼬리 끝을 가지런히 놓았다.

“작은 돌을 하나 깼어.”

고양이가 몽이의 앞발을 내려다보았다. 몽이는 발가락 사이에 낀 풀 한 가닥을 빼냈다. 둘은 그것을 한참 보다가 웃었다.

이야기를 다 하지 않아도 해는 천천히 기울었다. 몽이는 남은 빛이 잦아들 때까지 풀밭에 등을 기대었다.''',
  ),
  GardenMoment(
    GardenMomentTrigger.plant,
    '작은 그늘의 약속',
    '정원에 나무를 한 그루 심으면 열려요',
    '''몽이는 새로 심은 나무 곁의 흙을 앞발로 살살 눌렀다. 물을 붓자 흙빛이 짙어졌다. 아주 작은 잎 하나가 물방울의 무게에 고개를 숙였다.

“여기 누워도 될까?”

곁에 온 고양이가 나무 아래를 가리켰다. 그늘은 아직 앞발 하나를 겨우 덮었다. 몽이는 옆에 앉아 자기 그림자를 보탰다.

바람이 불 때마다 두 그림자 사이로 햇빛이 들어왔다. 고양이는 눈을 가늘게 뜨고 그 무늬를 따라갔다.

몽이는 빈 물뿌리개를 문 옆에 놓았다. 내일 물을 줄 때 찾기 쉬운 자리였다.''',
  ),
  GardenMoment(
    GardenMomentTrigger.letter,
    '접어 둔 편지',
    '편지를 한 번 남기면 열려요',
    '고양이는 봉투 모서리를 앞발로 살짝 눌렀다. 무슨 말부터 꺼내야 할지 고르던 시간이 그 안에 접혀 있었다.\n\n몽이는 편지 옆에 작은 잎을 놓았다. 답을 재촉하는 대신, 바람에 봉투가 날아가지 않도록 둘이 나란히 앉았다.',
  ),
  GardenMoment(
    GardenMomentTrigger.meditation,
    '바람이 쉬어 가는 자리',
    '오디오·영상 명상을 끝까지 들으면 열려요',
    '소리가 잦아들자 고양이는 기지개를 켰다. 몽이는 그 곁에 앉아 풀잎에 맺힌 빛을 바라보았다.\n\n아무 말도 보태지 않는 동안 작은 잎 하나가 펴졌다. 고양이는 눈을 가늘게 뜨고, 몽이는 꼬리를 풀밭 위에 내려놓았다.',
  ),
];
