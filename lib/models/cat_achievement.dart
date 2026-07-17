// 마음 돌보기의 여러 활동(출석/졸업/수집/애정표현 등)을 기준으로
// 달성 여부를 판단하는 업적(뱃지) 시스템.
//
// 뱃지는 한 번 달성하면 계속 유지되며(다시 잃지 않음), 힐링 정원의
// 잔잔한 톤에 맞춰 과하지 않은 개수(14개)로 구성했습니다.

/// 뱃지 판단에 필요한 누적 통계 스냅샷.
class CatAchievementStats {
  /// 누적 출석일수.
  final int growthDays;

  /// 지금까지 졸업시킨 고양이 수.
  final int graduatedCount;

  /// 보유 중인 옷·악세서리(착용형) 종류 수.
  final int ownedWearableCount;

  /// 보유 중인(우리 집에 놓인) 가구 종류 수.
  final int ownedFurnitureCount;

  /// 지금까지 사용한 먹거리·손질(소모품) 누적 횟수.
  final int totalConsumablesUsed;

  /// 지금까지 적립한 포인트의 누적 총량(현재 보유 포인트가 아니라, 써버린
  /// 포인트를 포함한 평생 누적치).
  final int totalPointsEarned;

  /// 하루 8가지 돌봄을 모두 완수한 날의 누적 횟수.
  final int totalFullCareDays;

  /// 고양이를 쓰다듬어준(탭) 누적 횟수.
  final int totalPats;

  const CatAchievementStats({
    this.growthDays = 0,
    this.graduatedCount = 0,
    this.ownedWearableCount = 0,
    this.ownedFurnitureCount = 0,
    this.totalConsumablesUsed = 0,
    this.totalPointsEarned = 0,
    this.totalFullCareDays = 0,
    this.totalPats = 0,
  });
}

class CatAchievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool Function(CatAchievementStats stats) isUnlocked;

  /// 잠겨있을 때 진행 상황을 "3/7일"처럼 짧게 보여주는 문구.
  final String Function(CatAchievementStats stats) progressLabel;

  const CatAchievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.progressLabel,
  });
}

String _clampedProgress(int value, int target) =>
    '${value > target ? target : value}/$target';

/// 전체 뱃지 목록.
final List<CatAchievement> catAchievements = [
  CatAchievement(
    id: 'attend_1',
    emoji: '🌱',
    title: '첫 만남',
    description: '아기 고양이와 처음 함께한 날',
    isUnlocked: (s) => s.growthDays >= 1,
    progressLabel: (s) => _clampedProgress(s.growthDays, 1),
  ),
  CatAchievement(
    id: 'attend_3',
    emoji: '🍀',
    title: '3일의 약속',
    description: '3일 연속 출석했어요',
    isUnlocked: (s) => s.growthDays >= 3,
    progressLabel: (s) => _clampedProgress(s.growthDays, 3),
  ),
  CatAchievement(
    id: 'attend_7',
    emoji: '🌤️',
    title: '꾸준한 일주일',
    description: '7일 동안 함께했어요',
    isUnlocked: (s) => s.growthDays >= 7,
    progressLabel: (s) => _clampedProgress(s.growthDays, 7),
  ),
  CatAchievement(
    id: 'attend_30',
    emoji: '🌿',
    title: '첫 성장',
    description: '30일 출석으로 소년 고양이가 되었어요',
    isUnlocked: (s) => s.growthDays >= 30,
    progressLabel: (s) => _clampedProgress(s.growthDays, 30),
  ),
  CatAchievement(
    id: 'full_care_7',
    emoji: '💯',
    title: '완벽한 하루들',
    description: '하루 8가지 돌봄을 모두 완수한 날이 7번 쌓였어요',
    isUnlocked: (s) => s.totalFullCareDays >= 7,
    progressLabel: (s) => _clampedProgress(s.totalFullCareDays, 7),
  ),
  CatAchievement(
    id: 'graduate_1',
    emoji: '🎓',
    title: '첫 졸업',
    description: '첫 고양이를 졸업시켰어요',
    isUnlocked: (s) => s.graduatedCount >= 1,
    progressLabel: (s) => _clampedProgress(s.graduatedCount, 1),
  ),
  CatAchievement(
    id: 'graduate_5',
    emoji: '🏆',
    title: '졸업 명인',
    description: '5마리를 졸업시켰어요',
    isUnlocked: (s) => s.graduatedCount >= 5,
    progressLabel: (s) => _clampedProgress(s.graduatedCount, 5),
  ),
  CatAchievement(
    id: 'wardrobe_5',
    emoji: '👗',
    title: '옷장 부자',
    description: '옷·악세서리 5종을 보유했어요',
    isUnlocked: (s) => s.ownedWearableCount >= 5,
    progressLabel: (s) => _clampedProgress(s.ownedWearableCount, 5),
  ),
  CatAchievement(
    id: 'wardrobe_10',
    emoji: '💎',
    title: '패셔니스타',
    description: '옷·악세서리 10종을 보유했어요',
    isUnlocked: (s) => s.ownedWearableCount >= 10,
    progressLabel: (s) => _clampedProgress(s.ownedWearableCount, 10),
  ),
  CatAchievement(
    id: 'furniture_3',
    emoji: '🏠',
    title: '인테리어 감각',
    description: '가구 3종을 우리 집에 놓았어요',
    isUnlocked: (s) => s.ownedFurnitureCount >= 3,
    progressLabel: (s) => _clampedProgress(s.ownedFurnitureCount, 3),
  ),
  CatAchievement(
    id: 'foodie_10',
    emoji: '🍣',
    title: '미식가',
    description: '먹거리·손질 아이템을 10번 사용했어요',
    isUnlocked: (s) => s.totalConsumablesUsed >= 10,
    progressLabel: (s) => _clampedProgress(s.totalConsumablesUsed, 10),
  ),
  CatAchievement(
    id: 'points_10',
    emoji: '🏅',
    title: '포인트 부자',
    description: '포인트를 누적 10점 모았어요',
    isUnlocked: (s) => s.totalPointsEarned >= 10,
    progressLabel: (s) => _clampedProgress(s.totalPointsEarned, 10),
  ),
  CatAchievement(
    id: 'affection_20',
    emoji: '💕',
    title: '애정 표현',
    description: '고양이를 20번 쓰다듬어줬어요',
    isUnlocked: (s) => s.totalPats >= 20,
    progressLabel: (s) => _clampedProgress(s.totalPats, 20),
  ),
  CatAchievement(
    id: 'affection_100',
    emoji: '💖',
    title: '애정 만렙',
    description: '고양이를 100번 쓰다듬어줬어요',
    isUnlocked: (s) => s.totalPats >= 100,
    progressLabel: (s) => _clampedProgress(s.totalPats, 100),
  ),
];
