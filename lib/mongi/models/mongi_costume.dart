/// "마음 상자" 가챠에서 뽑을 수 있는 몽이 코스튬(액세서리) 정의.
/// 실제 캐릭터 스프라이트를 새로 그리는 대신, CatPlayer 위에 겹쳐 그리는
/// 작은 액세서리 오버레이 이미지로 구현한다(비용 효율적인 코스메틱 확장).
/// 코스튬의 "희귀도" 태그. 예전에는 뽑힐 확률과 직결되어 있었지만, 지금은
/// 확률/천장 시스템 없이 순서만 무작위이고 반드시 새 아이템이 확정 지급되므로
/// 실제 등장 확률과는 무관하다 - 오직 도감 수집 성취감(등급 배지 색상 등)을
/// 위한 표시용 분류로만 남겨둔다.
enum CostumeRarity {
  common, // 일반
  rare, // 레어
  epic, // 에픽
  legendary, // 레전더리 (가장 희귀하게 "느껴지는" 표시용 등급)
}

class MongiCostume {
  final String id;
  final String name;
  final String imageAsset;
  final CostumeRarity rarity;

  /// 액세서리를 몽이 머리 위에 겹칠 때의 상대적 위치/크기 보정값.
  /// CatPlayer 크기(118x128) 기준, 머리 중심을 (0.5, 0.22)로 잡고
  /// 액세서리별로 살짝 다르게 튜닝한다.
  final double offsetXRatio;
  final double offsetYRatio;
  final double scaleRatio;

  const MongiCostume({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.rarity,
    this.offsetXRatio = 0.5,
    this.offsetYRatio = 0.16,
    this.scaleRatio = 0.62,
  });

  static const List<MongiCostume> all = [
    MongiCostume(
      id: 'ribbon',
      name: '핑크 리본',
      imageAsset: 'assets/mongi/images/costume_ribbon.png',
      rarity: CostumeRarity.common,
      offsetYRatio: 0.14,
      scaleRatio: 0.42,
    ),
    MongiCostume(
      id: 'star_band',
      name: '별빛 머리띠',
      imageAsset: 'assets/mongi/images/costume_star_band.png',
      rarity: CostumeRarity.common,
      offsetYRatio: 0.10,
      scaleRatio: 0.52,
    ),
    MongiCostume(
      id: 'scarf',
      name: '무지개 목도리',
      imageAsset: 'assets/mongi/images/costume_scarf.png',
      rarity: CostumeRarity.rare,
      offsetYRatio: 0.42,
      scaleRatio: 0.62,
    ),
    MongiCostume(
      id: 'bunny_ears',
      name: '토끼 귀 머리띠',
      imageAsset: 'assets/mongi/images/costume_bunny_ears.png',
      rarity: CostumeRarity.rare,
      offsetYRatio: -0.02,
      scaleRatio: 0.58,
    ),
    MongiCostume(
      id: 'flower_crown',
      name: '데이지 화관',
      imageAsset: 'assets/mongi/images/costume_flower_crown.png',
      rarity: CostumeRarity.epic,
      offsetYRatio: 0.08,
      scaleRatio: 0.58,
    ),
    MongiCostume(
      id: 'wizard_hat',
      name: '별빛 마법사 모자',
      imageAsset: 'assets/mongi/images/costume_wizard_hat.png',
      rarity: CostumeRarity.epic,
      offsetYRatio: -0.06,
      scaleRatio: 0.62,
    ),
    MongiCostume(
      id: 'golden_crown',
      name: '황금 왕관',
      imageAsset: 'assets/mongi/images/costume_golden_crown.png',
      rarity: CostumeRarity.legendary,
      offsetYRatio: 0.02,
      scaleRatio: 0.56,
    ),
    // ── 신규 코스튬 (다양한 아이템 확장) ──
    MongiCostume(
      id: 'cloud_band',
      name: '뭉게구름 머리띠',
      imageAsset: 'assets/mongi/images/costume_cloud_band.png',
      rarity: CostumeRarity.common,
      offsetYRatio: 0.10,
      scaleRatio: 0.56,
    ),
    MongiCostume(
      id: 'sunflower_band',
      name: '해바라기 머리띠',
      imageAsset: 'assets/mongi/images/costume_sunflower_band.png',
      rarity: CostumeRarity.common,
      offsetYRatio: 0.08,
      scaleRatio: 0.5,
    ),
    MongiCostume(
      id: 'angel_wings',
      name: '천사의 날개',
      imageAsset: 'assets/mongi/images/costume_angel_wings.png',
      rarity: CostumeRarity.rare,
      offsetYRatio: 0.38,
      scaleRatio: 0.7,
    ),
    MongiCostume(
      id: 'pirate_hat',
      name: '꼬마 해적 모자',
      imageAsset: 'assets/mongi/images/costume_pirate_hat.png',
      rarity: CostumeRarity.rare,
      offsetYRatio: -0.08,
      scaleRatio: 0.6,
    ),
    MongiCostume(
      id: 'galaxy_cape',
      name: '은하수 망토',
      imageAsset: 'assets/mongi/images/costume_galaxy_cape.png',
      rarity: CostumeRarity.epic,
      offsetYRatio: 0.42,
      scaleRatio: 0.68,
    ),
    MongiCostume(
      id: 'phoenix_crown',
      name: '불사조의 왕관',
      imageAsset: 'assets/mongi/images/costume_phoenix_crown.png',
      rarity: CostumeRarity.legendary,
      offsetYRatio: -0.04,
      scaleRatio: 0.6,
    ),
    // ── 한국적 코스튬 (색동/전통 소품) ──
    MongiCostume(
      id: 'saekdong_ribbon',
      name: '색동 리본',
      imageAsset: 'assets/mongi/images/costume_saekdong_ribbon.png',
      rarity: CostumeRarity.rare,
      offsetYRatio: 0.12,
      scaleRatio: 0.5,
    ),
    MongiCostume(
      id: 'bokjumeoni',
      name: '복주머니 머리띠',
      imageAsset: 'assets/mongi/images/costume_bokjumeoni.png',
      rarity: CostumeRarity.epic,
      offsetYRatio: 0.2,
      scaleRatio: 0.56,
    ),
    // 스타터팩 전용 - 가챠 풀에는 포함되지 않고, 첫 구매 스타터팩을 사면
    // 즉시 확정 지급되는 한정 코스튬("새로운 시작"을 상징하는 새싹 머리띠).
    MongiCostume(
      id: 'sprout_hat',
      name: '새싹 머리띠',
      imageAsset: 'assets/mongi/images/costume_sprout_hat.png',
      rarity: CostumeRarity.epic,
      offsetYRatio: 0.02,
      scaleRatio: 0.56,
    ),
  ];

  /// 가챠 확률 풀에 실제로 등장하는 코스튬만 모은 목록.
  /// [sprout_hat]처럼 특정 이벤트/구매로만 얻는 한정 코스튬은 제외한다.
  static List<MongiCostume> get gachaPool =>
      all.where((c) => c.id != 'sprout_hat').toList();

  static MongiCostume byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static String rarityLabel(CostumeRarity r) {
    switch (r) {
      case CostumeRarity.common:
        return '일반';
      case CostumeRarity.rare:
        return '레어';
      case CostumeRarity.epic:
        return '에픽';
      case CostumeRarity.legendary:
        return '레전더리';
    }
  }
}
