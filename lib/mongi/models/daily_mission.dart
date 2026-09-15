/// 일일 미션 시스템 모델.
///
/// 매일 자정(날짜 변경)에 진행도가 초기화되는 3개의 고정 미션을 제공한다.
/// "오늘 해야 할 일" 하나를 억지로 만들지 않고, 이미 앱을 플레이하면서
/// 자연스럽게 채워지는 지표(감정 먹기/스테이지 완료/마음 심기)를 그대로
/// 미션 목표로 재사용한다 - 새로운 강제 행동을 요구하지 않는다.
///
/// 처벌형이 아니라 "다 채우면 조금 더 받는" 보상 차등형 설계: 미션 하나당
/// 소소한 빛의 정수를 주고, 3개를 모두 완료하면 별조각까지 얹어주는 "올클리어
/// 보너스"로 완주 욕구를 자극한다.
enum DailyMissionType {
  /// 오늘 감정 몬스터를 먹은 총 개수(스테이지+엔드리스 합산).
  emotionsEaten,

  /// 오늘 스테이지 모드를 목표까지 다 채우고 완료한 횟수.
  stageCompleted,

  /// 오늘 "네, 심을래요"를 선택해 마음을 심은 횟수.
  plantedLove,
}

/// 미션 하나의 정의(목표/보상). 진행도 자체는 저장소([GardenStorage])에서
/// 미션 id별로 따로 관리되고, 이 클래스는 순수하게 "정의"만 담는다.
class DailyMissionDef {
  final String id;
  final DailyMissionType type;
  final String emoji;
  final String label;
  final int target;

  /// 이 미션을 완료(target 달성 + 수령)했을 때 받는 빛의 정수.
  final int rewardLightEssence;

  const DailyMissionDef({
    required this.id,
    required this.type,
    required this.emoji,
    required this.label,
    required this.target,
    required this.rewardLightEssence,
  });
}

class DailyMission {
  DailyMission._();

  /// 오늘의 미션 3종 (고정 - 매일 같은 3개가 반복되지만, 진행도는 매일 리셋된다).
  /// 뒤로 갈수록(더 많은 참여가 필요한 미션일수록) 보상도 함께 커지는
  /// 보상 차등형 설계를 따른다.
  static const List<DailyMissionDef> all = [
    DailyMissionDef(
      id: 'eat_emotions',
      type: DailyMissionType.emotionsEaten,
      emoji: '🍬',
      label: '감정 몬스터 15개 먹기',
      target: 15,
      rewardLightEssence: 10,
    ),
    DailyMissionDef(
      id: 'complete_stage',
      type: DailyMissionType.stageCompleted,
      emoji: '🏁',
      label: '스테이지 1번 끝까지 완료하기',
      target: 1,
      rewardLightEssence: 15,
    ),
    DailyMissionDef(
      id: 'plant_love',
      type: DailyMissionType.plantedLove,
      emoji: '🌱',
      label: '마음 2번 심기',
      target: 2,
      rewardLightEssence: 20,
    ),
  ];

  /// 3개 미션을 모두 완료(수령)했을 때 추가로 지급하는 "올클리어 보너스".
  /// 개별 미션 보상보다 눈에 띄게 크게 잡아, "오늘 다 채워볼까" 하는
  /// 동기를 하나 더 만든다.
  static const int allClearBonusLightEssence = 25;
  static const int allClearBonusStarShard = 1;

  static DailyMissionDef byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);
}
