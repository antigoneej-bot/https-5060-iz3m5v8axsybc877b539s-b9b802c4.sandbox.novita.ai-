/// 정원 플러스 포인트로 구매할 수 있는 반려 고양이 상점 아이템.
/// 별도의 이미지 에셋 없이도 바로 적용할 수 있도록, 이모지 하나로 표현되는
/// 가벼운 코스메틱/소모품 아이템입니다.
///
/// 아이템은 세 가지 종류로 나뉩니다:
/// - [CatItemType.wearable]: 고양이가 직접 착용하는 아이템 (모자/옷/신발/리본 등).
///   부위([CatWearSlot])별로 슬롯이 나뉘어 있어, 여러 부위를 동시에 착용할 수
///   있습니다(예: 모자 + 목도리 + 옷 + 신발을 한꺼번에).
/// - [CatItemType.consumable]: 사료/츄루/빗질처럼 한 번 사용하면 사라지는
///   소모품. 사용하면 마음 온도가 살짝 오릅니다.
/// - [CatItemType.furniture]: 캣타워처럼 고양이가 입는 게 아니라 '우리 집'을
///   꾸며주는 가구. 구매하면 바로 방에 놓여집니다.
enum CatItemType { wearable, consumable, furniture }

/// 착용형 아이템의 부위. 부위가 다르면 동시에 여러 개를 착용할 수 있습니다.
enum CatWearSlot { head, neck, body, feet, decor }

class CatAccessory {
  final String id;
  final String emoji;
  final String label;
  final int pointCost;
  final CatItemType type;

  /// [type]이 wearable일 때만 의미가 있는 착용 부위.
  final CatWearSlot? slot;

  const CatAccessory({
    required this.id,
    required this.emoji,
    required this.label,
    required this.pointCost,
    this.type = CatItemType.wearable,
    this.slot,
  });
}

/// 상점에서 판매하는 전체 아이템 목록.
const List<CatAccessory> catAccessories = [
  // ── 먹거리 · 손질 (소모품 - 사용하면 마음 온도가 살짝 올라요) ──
  CatAccessory(
    id: 'food_regular',
    emoji: '🍽️',
    label: '일반 사료',
    pointCost: 1,
    type: CatItemType.consumable,
  ),
  CatAccessory(
    id: 'food_dry',
    emoji: '🌾',
    label: '건식 사료',
    pointCost: 1,
    type: CatItemType.consumable,
  ),
  CatAccessory(
    id: 'food_wet',
    emoji: '🥫',
    label: '습식 사료',
    pointCost: 2,
    type: CatItemType.consumable,
  ),
  CatAccessory(
    id: 'churu_chicken',
    emoji: '🍗',
    label: '닭고기 츄루',
    pointCost: 1,
    type: CatItemType.consumable,
  ),
  CatAccessory(
    id: 'churu_tuna',
    emoji: '🐟',
    label: '참치 츄루',
    pointCost: 1,
    type: CatItemType.consumable,
  ),
  CatAccessory(
    id: 'churu_salmon',
    emoji: '🍣',
    label: '연어 츄루',
    pointCost: 2,
    type: CatItemType.consumable,
  ),
  CatAccessory(
    id: 'brush',
    emoji: '🪮',
    label: '빗질 브러시',
    pointCost: 1,
    type: CatItemType.consumable,
  ),

  // ── 옷 · 악세서리 (착용형 - 부위별로 동시에 착용할 수 있어요) ──
  CatAccessory(
    id: 'ribbon',
    emoji: '🎀',
    label: '리본',
    pointCost: 1,
    slot: CatWearSlot.decor,
  ),
  CatAccessory(
    id: 'flower',
    emoji: '🌸',
    label: '꽃 장식',
    pointCost: 1,
    slot: CatWearSlot.decor,
  ),
  CatAccessory(
    id: 'star',
    emoji: '⭐',
    label: '별 스티커',
    pointCost: 2,
    slot: CatWearSlot.decor,
  ),
  CatAccessory(
    id: 'glasses',
    emoji: '👓',
    label: '동그란 안경',
    pointCost: 3,
    slot: CatWearSlot.decor,
  ),
  CatAccessory(
    id: 'scarf',
    emoji: '🧣',
    label: '목도리',
    pointCost: 2,
    slot: CatWearSlot.neck,
  ),
  CatAccessory(
    id: 'bowtie',
    emoji: '🎗️',
    label: '보타이',
    pointCost: 3,
    slot: CatWearSlot.neck,
  ),
  CatAccessory(
    id: 'hat',
    emoji: '🎩',
    label: '멋쟁이 모자',
    pointCost: 4,
    slot: CatWearSlot.head,
  ),
  CatAccessory(
    id: 'crown',
    emoji: '👑',
    label: '왕관',
    pointCost: 5,
    slot: CatWearSlot.head,
  ),
  CatAccessory(
    id: 'headset',
    emoji: '🎧',
    label: '헤드셋',
    pointCost: 5,
    slot: CatWearSlot.head,
  ),
  CatAccessory(
    id: 'dress',
    emoji: '👗',
    label: '화사한 원피스',
    pointCost: 4,
    slot: CatWearSlot.body,
  ),
  CatAccessory(
    id: 'hoodie',
    emoji: '🧥',
    label: '후드 집업',
    pointCost: 4,
    slot: CatWearSlot.body,
  ),
  CatAccessory(
    id: 'vest',
    emoji: '🎽',
    label: '멋쟁이 조끼',
    pointCost: 3,
    slot: CatWearSlot.body,
  ),
  CatAccessory(
    id: 'sneakers',
    emoji: '👟',
    label: '운동화',
    pointCost: 3,
    slot: CatWearSlot.feet,
  ),

  // ── 우리 집 가구 (구매하면 바로 방에 놓여요 - 착용하는 게 아니에요) ──
  CatAccessory(
    id: 'cat_tower',
    emoji: '🗼',
    label: '캣타워',
    pointCost: 6,
    type: CatItemType.furniture,
  ),
  CatAccessory(
    id: 'cat_bed',
    emoji: '🛏️',
    label: '포근한 캣베드',
    pointCost: 4,
    type: CatItemType.furniture,
  ),
  CatAccessory(
    id: 'scratch_post',
    emoji: '🪵',
    label: '스크래처',
    pointCost: 3,
    type: CatItemType.furniture,
  ),
];

CatAccessory? catAccessoryById(String? id) {
  if (id == null) return null;
  for (final a in catAccessories) {
    if (a.id == id) return a;
  }
  return null;
}

/// 특정 종류(먹거리/옷/가구)의 아이템만 모아서 반환합니다.
List<CatAccessory> catAccessoriesByType(CatItemType type) =>
    catAccessories.where((a) => a.type == type).toList();

/// 부위 이름 (UI 표시용)
String catWearSlotLabel(CatWearSlot slot) {
  switch (slot) {
    case CatWearSlot.head:
      return '머리';
    case CatWearSlot.neck:
      return '목';
    case CatWearSlot.body:
      return '몸';
    case CatWearSlot.feet:
      return '발';
    case CatWearSlot.decor:
      return '장식';
  }
}
