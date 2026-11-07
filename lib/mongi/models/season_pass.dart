/// 시즌 패스("몽이의 마음여정") 모델.
///
/// F2P 표준 시즌 패스 패턴: 일정 기간(시즌) 동안만 유효한 진행 트랙을 두고,
/// 플레이할수록(+ 감사 기록 등 일상 습관을 남길 때도) 쌓이는 "시즌 경험치"로
/// 레벨을 올려 무료/프리미엄 두 트랙의 보상을 차례로 "수령"하게 만든다.
/// [GardenProvider.score](영구 나무 성장 점수)와는 완전히 별개의 지표로,
/// 시즌이 끝나면 경험치와 수령 기록이 함께 리셋되고 다음 시즌이 새로
/// 시작된다(단, 이미 수령한 보상 자체(재화/코스튬)는 영구히 남는다).
///
/// "1번 개선": 순수 소비-과금 트랙에서 "힐링 마일스톤" 성격을 더하기 위해
/// 5의 배수 레벨(5/10/15/20)은 [milestoneMessage]라는 짧은 격려 문구를
/// 함께 지녀, 그 레벨에 도달하는 순간 재화 대신(또는 재화와 함께) "지금까지
/// 잘 해왔다"는 메시지가 뜨도록 한다(도달 시점 표시는 GardenProvider/
/// SeasonPassScreen에서 처리).
class SeasonPass {
  SeasonPass._();

  /// 한 시즌의 길이(일).
  static const int seasonLengthDays = 14;

  /// 시즌 패스 최고 레벨.
  static const int maxLevel = 20;

  /// 레벨 하나를 올리기 위해 필요한 시즌 경험치.
  static const int xpPerLevel = 90;

  /// 최고 레벨까지 필요한 총 경험치.
  static int get totalXpForMaxLevel => maxLevel * xpPerLevel;

  /// 지금 시즌 경험치로 도달한 레벨(0~[maxLevel]).
  static int levelForXp(int xp) {
    if (xp <= 0) return 0;
    final lvl = xp ~/ xpPerLevel;
    return lvl.clamp(0, maxLevel);
  }

  /// 지금 레벨 안에서 진행 중인 경험치(다음 레벨까지 필요한 것 대비).
  /// 이미 최고 레벨이면 0을 반환한다.
  static int xpIntoCurrentLevel(int xp) {
    final lvl = levelForXp(xp);
    if (lvl >= maxLevel) return 0;
    return (xp - lvl * xpPerLevel).clamp(0, xpPerLevel);
  }

  /// 다음 레벨업까지 필요한 경험치(칸 전체 크기). 이미 최고 레벨이면 0.
  static int xpForNextLevelSpan(int xp) {
    final lvl = levelForXp(xp);
    return lvl >= maxLevel ? 0 : xpPerLevel;
  }

  /// 레벨별 무료/프리미엄 보상 트랙. index 0 = 레벨 1.
  ///
  /// 무료 트랙은 꾸준히 참여하면 누구나 챙길 수 있는 소소한 재화 위주로,
  /// 프리미엄 트랙은 같은 레벨이라도 훨씬 풍성한 재화 + 5의 배수 레벨마다
  /// 별조각 보너스, 마지막 20레벨엔 확정 코스튬("황금 왕관")까지 지급한다.
  static final List<SeasonPassTier> tiers = List.generate(maxLevel, (i) {
    final level = i + 1;
    final isMilestone5 = level % 5 == 0;
    final isFinale = level == maxLevel;

    final freeLight = 15 + level * 4;
    final free = SeasonRewardItem(
      emoji: isMilestone5 ? '⭐' : '💡',
      label: isMilestone5
          ? '빛의 정수 $freeLight개 + 별조각 ${(level ~/ 5) * 2}개'
          : '빛의 정수 $freeLight개',
      lightEssence: freeLight,
      starShard: isMilestone5 ? (level ~/ 5) * 2 : 0,
    );

    final premiumLight = 30 + level * 8;
    final premiumShard = 5 + level * 2;
    final premium = SeasonRewardItem(
      emoji: isFinale ? '👑' : (isMilestone5 ? '💎' : '✨'),
      label: isFinale
          ? '빛의 정수 ${premiumLight + 150}개 + 별조각 ${premiumShard + 20}개 + 확정 코스튬 "황금 왕관"'
          : '빛의 정수 $premiumLight개 + 별조각 $premiumShard개',
      lightEssence: isFinale ? premiumLight + 150 : premiumLight,
      starShard: isFinale ? premiumShard + 20 : premiumShard,
      costumeId: isFinale ? 'golden_crown' : null,
    );

    return SeasonPassTier(level: level, free: free, premium: premium);
  }, growable: false);

  static SeasonPassTier tierForLevel(int level) =>
      tiers[(level - 1).clamp(0, maxLevel - 1)];

  /// [level]이 "마음 마일스톤"(5의 배수 레벨)인지 여부.
  static bool isMindMilestone(int level) => level % 5 == 0;

  /// 마음 마일스톤 레벨에 도달했을 때 보여줄 짧은 격려 문구. 마일스톤이
  /// 아닌 레벨이면 null.
  static String? milestoneMessageForLevel(int level) {
    switch (level) {
      case 5:
        return '벌써 5레벨! 매일 조금씩 마음을 돌보고 있다는 증거예요 🌱';
      case 10:
        return '절반을 지났어요. 그동안 쌓아온 하루하루가 정말 소중해요 🌿';
      case 15:
        return '15레벨, 이제 얼마 남지 않았어요. 꾸준함이 참 대단해요 🌳';
      case 20:
        return '이번 시즌의 마음여정을 완주했어요! 몽이가 가장 자랑스러워하는 순간이에요 🌟';
      default:
        return null;
    }
  }
}

/// 한 레벨에서 얻을 수 있는 보상 하나(무료 또는 프리미엄 한 칸).
class SeasonRewardItem {
  final String emoji;
  final String label;
  final int lightEssence;
  final int starShard;
  final String? costumeId;

  const SeasonRewardItem({
    required this.emoji,
    required this.label,
    this.lightEssence = 0,
    this.starShard = 0,
    this.costumeId,
  });
}

/// 시즌 패스 한 레벨의 무료/프리미엄 보상 한 쌍.
class SeasonPassTier {
  final int level;
  final SeasonRewardItem free;
  final SeasonRewardItem premium;

  const SeasonPassTier({
    required this.level,
    required this.free,
    required this.premium,
  });
}
