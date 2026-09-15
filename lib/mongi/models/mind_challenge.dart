/// "마음 챌린지" - Finch의 "Goal Journeys"를 벤치마킹한 테마별 다일(多日) 여정
/// 시스템 모델.
///
/// 기존 개별 감정 처리(게임 1판 = 1감정)를 넘어, "요즘 자존감이 낮아요" 같은
/// 테마를 하나 골라서 7일 동안 매일 조금씩 마음을 돌보는 짧은 서사를 만든다.
/// 시즌 패스("몽이의 마음여정")와 이름이 겹치지 않도록 "챌린지"라는 이름을
/// 쓴다 - 시즌 패스는 "계속 플레이하면 쌓이는 재화 트랙"이고, 마음 챌린지는
/// "한 테마를 골라 며칠간 완주하는 목표 지향적 여정"으로 서로 다른 개념이다.
///
/// 하루의 완료 조건은 기존에 있는 "오늘의 감정 체크인"([GardenProvider.
/// recordDailyCheckIn])을 그대로 재사용한다 - 새로운 강제 행동을 만들지
/// 않는다는 원칙을 그대로 따른다. 체크인이 하루 한 번으로 자연히 제한되므로,
/// 챌린지도 자연스럽게 실제 날짜에 걸쳐 진행된다(하루에 몰아서 7일을 끝낼 수
/// 없다).
class MindChallengeDef {
  final String id;
  final String emoji;

  /// 하위 호환/저장소 로직 공유를 위해 한국어로 고정된 제목 - 화면에서는
  /// [mind_challenge_l10n.dart]의 헬퍼를 통해 다국어로 바꿔서 표시한다.
  final String title;
  final String description;

  /// 이 챌린지의 총 기간(일). 하루에 한 번, 그날의 감정 체크인을 하면 그
  /// 날짜가 진행도로 기록된다.
  final int durationDays;

  /// 날짜별(1일차~durationDays일차) 짧은 응원/안내 문구. length는 항상
  /// [durationDays]와 같다.
  final List<String> dailyPrompts;

  /// 하루를 완료할 때마다 받는 소량의 빛의 정수.
  final int rewardLightEssencePerDay;

  /// [durationDays]일을 모두 완료했을 때 추가로 받는 완주 보너스.
  final int completionBonusLightEssence;
  final int completionBonusStarShard;

  const MindChallengeDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.dailyPrompts,
    required this.rewardLightEssencePerDay,
    required this.completionBonusLightEssence,
    required this.completionBonusStarShard,
  });
}

class MindChallenge {
  MindChallenge._();

  /// 지금 고를 수 있는 테마 4종. 각 7일 구성이며, 뒤로 갈수록(더 무거운
  /// 테마일수록) 완주 보너스가 커지는 보상 차등형 설계를 따른다.
  static const List<MindChallengeDef> all = [
    MindChallengeDef(
      id: 'self_esteem',
      emoji: '🌷',
      title: '자존감 돌보기',
      description: '7일 동안 매일 나에게 다정한 말을 건네며 자존감을 천천히 채워가요.',
      durationDays: 7,
      dailyPrompts: [
        '1일차: 오늘 나에게 잘한 일 한 가지를 떠올려보세요.',
        '2일차: 거울 속 나에게 "고생했어"라고 말해보세요.',
        '3일차: 나의 장점 하나를 적어보세요.',
        '4일차: 오늘은 나를 비교하지 않는 날로 정해보세요.',
        '5일차: 작은 성취 하나에도 스스로를 칭찬해주세요.',
        '6일차: 나를 힘들게 하는 생각 하나를 조금 다르게 바라봐요.',
        '7일차: 지난 6일을 돌아보며 나에게 편지를 써보세요.',
      ],
      rewardLightEssencePerDay: 8,
      completionBonusLightEssence: 60,
      completionBonusStarShard: 2,
    ),
    MindChallengeDef(
      id: 'anxiety_calm',
      emoji: '🌊',
      title: '불안 다스리기',
      description: '7일 동안 매일 잠시 멈춰 숨을 고르며 불안한 마음을 가라앉혀요.',
      durationDays: 7,
      dailyPrompts: [
        '1일차: 지금 느끼는 불안에 이름을 붙여보세요.',
        '2일차: 천천히 숨을 4번 들이쉬고 내쉬어 보세요.',
        '3일차: 지금 당장 할 수 있는 아주 작은 일 하나만 해보세요.',
        '4일차: "이 순간은 지나간다"는 것을 떠올려보세요.',
        '5일차: 걱정을 종이에 적어 눈에 보이게 꺼내보세요.',
        '6일차: 오늘 하루, 확실한 것 세 가지를 찾아보세요.',
        '7일차: 일주일간 불안이 어떻게 변했는지 돌아보세요.',
      ],
      rewardLightEssencePerDay: 8,
      completionBonusLightEssence: 60,
      completionBonusStarShard: 2,
    ),
    MindChallengeDef(
      id: 'burnout_recovery',
      emoji: '🔋',
      title: '번아웃 회복',
      description: '7일 동안 매일 조금씩 쉬어가며 지친 마음을 회복해요.',
      durationDays: 7,
      dailyPrompts: [
        '1일차: 오늘 하루, 꼭 하지 않아도 되는 일 하나를 내려놓아 보세요.',
        '2일차: 잠깐이라도 아무것도 하지 않는 시간을 가져보세요.',
        '3일차: 나를 지치게 하는 것 하나를 알아차려 보세요.',
        '4일차: 좋아하는 것을 5분만 해보세요.',
        '5일차: "충분히 했다"고 스스로에게 말해주세요.',
        '6일차: 오늘은 평소보다 조금 일찍 쉬어보세요.',
        '7일차: 이번 주 나를 돌본 방법들을 적어보세요.',
      ],
      rewardLightEssencePerDay: 8,
      completionBonusLightEssence: 70,
      completionBonusStarShard: 2,
    ),
    MindChallengeDef(
      id: 'gratitude_habit',
      emoji: '🌻',
      title: '감사 습관 만들기',
      description: '7일 동안 매일 감사한 순간을 찾아보며 긍정적인 시선을 길러요.',
      durationDays: 7,
      dailyPrompts: [
        '1일차: 오늘 감사했던 순간 하나를 떠올려보세요.',
        '2일차: 나를 도와준 사람 한 명을 생각해보세요.',
        '3일차: 당연하게 여겼던 것 하나에 감사해보세요.',
        '4일차: 오늘의 날씨나 풍경에서 좋은 점을 찾아보세요.',
        '5일차: 내가 가진 것 중 감사한 것 하나를 적어보세요.',
        '6일차: 오늘 나에게 있었던 작은 행운을 찾아보세요.',
        '7일차: 일주일간 발견한 감사한 순간들을 돌아보세요.',
      ],
      rewardLightEssencePerDay: 8,
      completionBonusLightEssence: 55,
      completionBonusStarShard: 2,
    ),
  ];

  static MindChallengeDef byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);
}
