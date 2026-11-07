import 'mongi_garden_data.dart';

class GardenStoryChapter {
  final String title;
  final String body;
  const GardenStoryChapter(this.title, this.body);
}

class GardenStoryPack {
  final String month;
  final String title;
  final List<GardenStoryChapter> chapters;
  const GardenStoryPack(this.month, this.title, this.chapters);
  bool released(DateTime now) =>
      month.compareTo(MongiGardenData.dayKey(now).substring(0, 7)) <= 0;
  int recordDays(MongiGardenData data) =>
      data.recordDays.where((day) => day.compareTo('$month-01') >= 0).length;
  int requiredDays(int chapter) => [0, 3, 5][chapter];
  bool canOpen(MongiGardenData data, int chapter, bool premium, DateTime now) {
    if (chapter < 0 || chapter >= chapters.length || !released(now)) {
      return false;
    }
    final read = data.storyProgress[month] ?? 0;
    if (chapter < read || chapter == 0) return true;
    return premium &&
        read >= chapter &&
        recordDays(data) >= requiredDays(chapter);
  }
}

const gardenStories = <GardenStoryPack>[
  GardenStoryPack('2026-09', '빈 화분의 자리', [
    GardenStoryChapter(
      '하나 남은 자리',
      '''몽이는 정원 한쪽에 작은 화분을 놓았다. 씨앗도 흙도 없는 화분이었다.

“여기에는 뭘 심을 거야?”
옆을 지나던 고양이가 물었다. 몽이는 화분 안을 한 번 들여다보고는 귀를 기울였다. 빈 화분에는 바람 소리가 조금 더 또렷하게 들렸다.

“아직 모르겠어.”

그날 저녁, 몽이는 화분을 치우지 않았다. 대신 햇빛이 너무 뜨겁지 않은 자리로 조금 옮겨 놓았다. 무엇을 심을지 정하지 못한 물건도 정원에 있어도 괜찮을 것 같았다.''',
    ),
    GardenStoryChapter(
      '아무것도 심지 않은 날',
      '''며칠 동안 화분은 그대로였다. 다른 화분에서는 새잎이 돋았고, 작은 꽃 하나는 벌써 고개를 들었다. 몽이는 빈 화분 앞을 지날 때마다 발걸음을 조금 빨리했다.

어느 오후, 가장 어린 고양이가 그 안에 쏙 들어가 잠들었다. 둥글게 만 꼬리가 화분 가장자리에 걸렸다. 몽이는 깨우려다가 멈췄다.

그늘이 움직이자 화분도 조금 옮겼다. 잠든 고양이는 눈을 뜨지 않았다.

아무것도 자라지 않은 줄 알았는데, 그곳에는 누군가 편히 쉴 자리가 생겨 있었다. 몽이는 화분 아래에 받침을 하나 더 놓았다.''',
    ),
    GardenStoryChapter(
      '이름을 붙이는 저녁',
      '''어린 고양이가 떠난 뒤 화분 바닥에 작은 씨앗 하나가 남았다. 어디서 묻어 왔는지는 알 수 없었다. 몽이는 흙을 조금 담고 씨앗을 눕혔다.

이름표 앞에서 한참을 망설였다. 무슨 꽃이 될지도, 언제 싹이 날지도 몰랐다. 결국 몽이는 짧게 썼다.

‘기다려 준 자리.’

물을 주고 돌아서는데 뒤에서 바람 소리가 났다. 비어 있을 때 들리던 것과 비슷한 소리였다. 화분이 채워져도 그 시간은 없어지지 않았다. 몽이는 내일도 같은 길로 산책하기로 했다.''',
    ),
  ]),
  GardenStoryPack('2026-10', '비를 듣는 벤치', [
    GardenStoryChapter(
      '젖은 발자국',
      '''비가 내리던 날, 몽이는 정원을 한 바퀴 돌기도 전에 발을 흠뻑 적셨다. 정해 둔 일을 다 하지 못한 것이 마음에 걸렸다. 벤치 아래에 들어가 발바닥을 핥는데, 빗방울이 나뭇잎을 두드렸다.

큰 잎에서는 낮은 소리가, 작은 잎에서는 빠른 소리가 났다. 몽이는 어느 쪽이 더 좋은지 고르다가 그만두었다. 두 소리가 번갈아 들릴 때가 더 재미있었다.

돌아갈 길에는 발자국이 남지 않았다. 비가 바로 지워 버렸기 때문이다. 그래도 몽이의 발은 자기가 걸어온 길을 알고 있었다.''',
    ),
    GardenStoryChapter(
      '벤치의 절반',
      '''다음 비 오는 날, 몽이는 작은 수건을 가져왔다. 벤치를 닦으려는데 낯선 고양이가 한쪽 끝에 앉아 있었다. 몽이는 반대편만 닦았다.

둘은 오래 말하지 않았다. 빗소리가 커지면 조금 가까이 앉았고, 작아지면 저마다 다른 곳을 바라보았다. 몽이는 왜 왔는지 물어보고 싶었지만, 옆에 머무는 것으로 대신했다.

비가 그치자 고양이가 수건을 반듯하게 접어 놓았다.
“여기, 내일도 앉아도 돼?”
몽이는 벤치의 빈 절반을 앞발로 톡 두드렸다.''',
    ),
    GardenStoryChapter(
      '맑은 날의 소리',
      '''모처럼 하늘이 맑았다. 몽이는 벤치 위 수건을 햇빛에 널었다. 비가 없으니 정원이 조용할 줄 알았는데, 잎사귀끼리 스치는 소리와 흙을 밟는 소리가 들렸다.

낯선 고양이가 다시 왔다. 오늘은 작은 돌 두 개를 가져왔다. 하나는 벤치 아래에, 하나는 몽이 앞에 놓았다.
“비가 오면 소리가 날까?”

아직 알 수 없었다. 둘은 돌의 자리를 몇 번 바꾸었다. 비를 기다릴 이유가 하나 생겼지만, 맑은 날을 서둘러 보내고 싶지는 않았다. 수건은 천천히 말라 갔다.''',
    ),
  ]),
  GardenStoryPack('2026-11', '낙엽이 머무는 곳', [
    GardenStoryChapter(
      '쓸어도 남는 것',
      '''몽이는 아침마다 낙엽을 쓸었다. 한쪽을 깨끗이 하면 반대쪽에 잎이 내려앉았다. 빗자루를 내려놓고 올려다보니, 가지에는 아직 많은 잎이 남아 있었다.

몽이는 가장 붉은 잎 하나를 집었다. 끝이 조금 찢어졌고 가운데에는 가느다란 선이 여러 갈래로 나 있었다. 멀리서 볼 때는 모두 같은 낙엽이었는데 손에 올리니 달랐다.

그날은 길 가운데만 쓸었다. 나무 밑에는 부드러운 잎더미를 남겨 두었다. 지나가던 고양이가 그 위를 밟고 바스락 소리에 깜짝 놀랐다.''',
    ),
    GardenStoryChapter(
      '책갈피',
      '''몽이는 붉은 잎을 편지 사이에 넣었다. 며칠 뒤 꺼내 보니 색이 조금 옅어져 있었다. 처음처럼 보관하지 못한 것 같아 아쉬웠다.

그러다 잎 가장자리에 남은 작은 흙자국을 발견했다. 그날 앞발이 젖어 있었던 것이 생각났다. 바람이 세게 불었고, 정원 입구에서 누군가 몽이의 이름을 불렀다.

색은 달라졌지만 잎은 다른 기억을 데려왔다. 몽이는 날짜를 적은 종이를 옆에 끼웠다. 무엇을 느꼈는지 모두 쓰지는 않았다. ‘바람이 세던 날’이라는 한 줄이면 오늘은 충분했다.''',
    ),
    GardenStoryChapter(
      '봄을 위한 빈칸',
      '''나뭇가지가 한결 가벼워졌다. 몽이는 정원 지도를 펴고 나무 아래에 작은 동그라미를 그렸다. 봄에 무언가 심고 싶은 자리였다.

무엇을 심을지는 아직 정하지 않았다. 옆에 앉은 고양이가 동그라미 안에 앞발을 올려 작은 얼룩을 남겼다. 몽이는 지우개를 찾다가 웃었다. 얼룩이 화분처럼 보였다.

책갈피 속 낙엽과 지도 위 얼룩을 번갈아 보았다. 정원에는 계획한 것과 우연히 남은 것이 함께 있었다. 몽이는 지도를 접고, 오늘의 햇빛이 닿는 자리로 옮겨 앉았다.''',
    ),
  ]),
];
