import 'package:flutter/material.dart';

/// "몽이 돌봄 세트" - 참치캔/사료/맑은물 같은 소모품으로 몽이를 직접
/// 돌봐주는 다마고치 스타일 아이템 정의.
///
/// - [MongiCareItemType.consumable]: 빛의 정수로 사서 즉시 "먹이는" 소모품.
///   몇 번을 주든 계속 살 수 있고, 줄 때마다 누적 카운트가 올라간다.
/// - [MongiCareItemType.keepsake]: 몽이의 집 / 담요처럼 한 번 선물하면
///   영구히 정원 씬에 자리를 잡는 특별한 선물(장식과 비슷하지만, 마일스톤이
///   아니라 빛의 정수로 직접 구매해서 잠금 해제한다).
enum MongiCareItemType { consumable, keepsake }

class MongiCareItem {
  final String id;
  final String name;
  final String emoji;
  final int lightEssenceCost;

  /// 이 아이템을 줬을 때 보여줄 몽이의 반응 대사.
  final String reactionMessage;
  final MongiCareItemType type;

  /// keepsake 전용: 정원 씬에 배치될 위치(-1.0~1.0 상대 좌표).
  final Alignment sceneAnchor;
  final double sceneScale;

  const MongiCareItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lightEssenceCost,
    required this.reactionMessage,
    required this.type,
    this.sceneAnchor = Alignment.center,
    this.sceneScale = 1.0,
  });

  bool get isKeepsake => type == MongiCareItemType.keepsake;

  static MongiCareItem byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static const List<MongiCareItem> all = [
    // ── 소모품: 언제든 다시 사서 줄 수 있는 먹이/물 ──
    MongiCareItem(
      id: 'tuna_can',
      name: '참치캔',
      emoji: '🐟',
      lightEssenceCost: 15,
      reactionMessage: '몽이가 참치캔을 냠냠 먹었어요! 세상 행복한 표정이에요 🐟',
      type: MongiCareItemType.consumable,
    ),
    MongiCareItem(
      id: 'kibble',
      name: '몽이 사료',
      emoji: '🍚',
      lightEssenceCost: 10,
      reactionMessage: '몽이가 사료를 오독오독 씹어 먹었어요 🍚',
      type: MongiCareItemType.consumable,
    ),
    MongiCareItem(
      id: 'clean_water',
      name: '맑은 물',
      emoji: '💧',
      lightEssenceCost: 8,
      reactionMessage: '몽이가 시원한 물을 마시고 개운해했어요 💧',
      type: MongiCareItemType.consumable,
    ),
    MongiCareItem(
      id: 'injeolmi',
      name: '인절미',
      emoji: '🍡',
      lightEssenceCost: 12,
      reactionMessage: '몽이가 콩고물 인절미를 오물오물 먹었어요! 쫀득쫀득 맛있대요 🍡',
      type: MongiCareItemType.consumable,
    ),
    // ── 특별한 선물: 한 번 선물하면 정원에 영구히 자리 잡는 keepsake ──
    MongiCareItem(
      id: 'blanket',
      name: '포근한 담요',
      emoji: '🧣',
      lightEssenceCost: 40,
      reactionMessage: '몽이가 담요를 덮고 따뜻하게 잠들었어요. 이제 정원 한켠이 더 아늑해졌어요 🧣',
      type: MongiCareItemType.keepsake,
      sceneAnchor: Alignment(-0.68, 0.80),
      sceneScale: 0.85,
    ),
    MongiCareItem(
      id: 'mongi_house',
      name: '몽이의 집',
      emoji: '🏠',
      lightEssenceCost: 60,
      reactionMessage: '몽이가 새 집을 마음에 들어해요! 이제 정원에 몽이만의 아늑한 집이 생겼어요 🏠',
      type: MongiCareItemType.keepsake,
      sceneAnchor: Alignment(0.62, -0.05),
      sceneScale: 1.05,
    ),
  ];
}

/// [MongiCareItem]을 구매해 몽이에게 준 직후의 결과. UI에서 반응 메시지를
/// 스낵바/토스트로 보여줄 때 사용한다.
class MongiCareResult {
  final MongiCareItem item;

  /// keepsake를 이번에 처음 획득했는지(=정원에 새로 배치됐는지) 여부.
  final bool isNewKeepsake;

  const MongiCareResult({required this.item, this.isNewKeepsake = false});
}
