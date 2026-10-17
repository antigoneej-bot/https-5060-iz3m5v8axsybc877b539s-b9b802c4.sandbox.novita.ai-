import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../models/cat_accessory.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';

/// 정원 플러스 포인트 상점 - 마음 온도가 100도에 닿을 때마다 쌓이는
/// 포인트로 반려 고양이를 돌보고 꾸며줄 수 있는 다양한 아이템을 구매하는
/// 화면입니다. 아이템은 세 가지로 나뉘어요:
/// - 먹거리·손질(소모품): 구매해서 보관함에 모아두고, "사용하기"를 누르면
///   1개가 줄면서 마음 온도가 살짝 올라요.
/// - 옷·악세서리(착용형): 부위별로 여러 개를 동시에 착용할 수 있어요.
/// - 우리집 가구: 구매하면 바로 우리 집에 놓인 것으로 취급돼요.
class CatShopScreen extends StatelessWidget {
  const CatShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final consumables = catAccessoriesByType(CatItemType.consumable);
    final wearables = catAccessoriesByType(CatItemType.wearable);
    final furniture = catAccessoriesByType(CatItemType.furniture);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassBlob(
          accent: AppColors.gold,
          background: const Color(0xFFFCEFD2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Text('🏅', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '보유 포인트',
                      style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                    ),
                    Text(
                      '마음에 드는 아이템을 골라 꾸며보세요',
                      style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Text(
                '${care.points}점',
                style: numberFont(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ShopSectionSignpost(
          emoji: '🍽️',
          title: '먹거리 · 손질',
          subtitle: '구매해서 보관함에 모아두고, 필요할 때 "사용하기"로 챙겨주세요',
        ),
        const SizedBox(height: 10),
        _ConsumableRow(items: consumables, care: care),
        const SizedBox(height: 26),
        _ShopSectionSignpost(
          emoji: '👕',
          title: '옷 · 악세서리',
          subtitle: '부위가 다르면 여러 개를 한꺼번에 착용할 수 있어요',
        ),
        const SizedBox(height: 10),
        ...wearables.map((accessory) {
          final owned = care.ownedAccessoryIds.contains(accessory.id);
          final equipped =
              accessory.slot != null &&
              care.equippedBySlot[accessory.slot] == accessory.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccessoryTile(
              accessory: accessory,
              owned: owned,
              equipped: equipped,
              canAfford: care.points >= accessory.pointCost,
              onBuy: () async {
                final success = await care.purchaseAccessory(accessory);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '포인트가 부족해요. ${accessory.pointCost}점이 필요해요.',
                      ),
                    ),
                  );
                }
              },
              onEquip: () => care.equipToSlot(accessory.slot!, accessory.id),
              onUnequip: () => care.equipToSlot(accessory.slot!, null),
            ),
          );
        }),
        const SizedBox(height: 26),
        _ShopSectionSignpost(
          emoji: '🏠',
          title: '우리집 가구',
          subtitle: '구매하면 바로 우리 집에 놓여요 · 입는 게 아니라 꾸미는 아이템이에요',
        ),
        const SizedBox(height: 10),
        ...furniture.map((accessory) {
          final owned = care.ownedAccessoryIds.contains(accessory.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FurnitureTile(
              accessory: accessory,
              owned: owned,
              canAfford: care.points >= accessory.pointCost,
              onBuy: () async {
                final success = await care.purchaseAccessory(accessory);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '포인트가 부족해요. ${accessory.pointCost}점이 필요해요.',
                      ),
                    ),
                  );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ShopSectionSignpost extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _ShopSectionSignpost({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: pathLabelFont(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 먹거리·손질(소모품) 아이템 - 가로 스크롤 카드로 보여주고, 보관함 개수와
/// "사용하기" 버튼을 함께 표시합니다.
class _ConsumableRow extends StatelessWidget {
  final List<CatAccessory> items;
  final CatCareProvider care;
  const _ConsumableRow({required this.items, required this.care});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 6,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final accessory = items[i];
          final count = care.consumableInventory[accessory.id] ?? 0;
          return _ConsumableCard(
            accessory: accessory,
            count: count,
            canAfford: care.points >= accessory.pointCost,
            onBuy: () async {
              final success = await care.purchaseAccessory(accessory);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('포인트가 부족해요. ${accessory.pointCost}점이 필요해요.'),
                  ),
                );
              }
            },
            onUse: count > 0
                ? () async {
                    final success = await care.useConsumable(accessory);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${accessory.label}${_particle(accessory.label)} 주었어요! 마음 온도가 살짝 올랐어요.',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                : null,
          );
        },
      ),
    );
  }

  String _particle(String word) {
    if (word.isEmpty) return '을';
    final last = word.runes.last;
    final hasJong = (last - 0xAC00) % 28 != 0;
    return hasJong ? '을' : '를';
  }
}

class _ConsumableCard extends StatelessWidget {
  final CatAccessory accessory;
  final int count;
  final bool canAfford;
  final VoidCallback onBuy;
  final VoidCallback? onUse;
  const _ConsumableCard({
    required this.accessory,
    required this.count,
    required this.canAfford,
    required this.onBuy,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.blobPeachAccent;
    final background = AppColors.blobPeach;
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background.withValues(alpha: 0.7),
            background.withValues(alpha: 0.4),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(accessory.emoji, style: const TextStyle(fontSize: 22)),
              const Spacer(),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'x$count',
                    style: numberFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            accessory.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pathLabelFont(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${accessory.pointCost}점',
            style: bodyFont(fontSize: 10, color: AppColors.inkSoft),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: onUse != null
                ? _SmallButton(
                    label: '사용하기',
                    color: accent,
                    filled: true,
                    onTap: onUse!,
                  )
                : _SmallButton(
                    label: '구매',
                    color: canAfford ? accent : AppColors.inkSoft,
                    filled: canAfford,
                    onTap: onBuy,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryTile extends StatelessWidget {
  final CatAccessory accessory;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final VoidCallback onBuy;
  final VoidCallback onEquip;
  final VoidCallback onUnequip;

  const _AccessoryTile({
    required this.accessory,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.onBuy,
    required this.onEquip,
    required this.onUnequip,
  });

  @override
  Widget build(BuildContext context) {
    final accent = equipped
        ? AppColors.blobMintAccent
        : (owned ? AppColors.blobPeachAccent : AppColors.blobLavenderAccent);
    final background = equipped
        ? AppColors.blobMint
        : (owned ? AppColors.blobPeach : AppColors.blobLavender);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background.withValues(alpha: 0.75),
            background.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            child: Text(accessory.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accessory.label,
                  style: pathLabelFont(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  owned
                      ? '보유 중 · ${catWearSlotLabel(accessory.slot!)} 부위'
                      : '${accessory.pointCost}점 · ${catWearSlotLabel(accessory.slot!)} 부위',
                  style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          if (equipped)
            _SmallButton(
              label: '해제',
              color: accent,
              filled: false,
              onTap: onUnequip,
            )
          else if (owned)
            _SmallButton(
              label: '장착',
              color: accent,
              filled: true,
              onTap: onEquip,
            )
          else
            _SmallButton(
              label: '구매',
              color: canAfford ? accent : AppColors.inkSoft,
              filled: canAfford,
              onTap: onBuy,
            ),
        ],
      ),
    );
  }
}

/// 가구 아이템 - 장착 개념 없이, 보유하면 바로 '우리 집'에 놓인 것으로
/// 표시합니다.
class _FurnitureTile extends StatelessWidget {
  final CatAccessory accessory;
  final bool owned;
  final bool canAfford;
  final VoidCallback onBuy;

  const _FurnitureTile({
    required this.accessory,
    required this.owned,
    required this.canAfford,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final accent = owned
        ? AppColors.blobMintAccent
        : AppColors.blobLavenderAccent;
    final background = owned ? AppColors.blobMint : AppColors.blobLavender;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background.withValues(alpha: 0.75),
            background.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            child: Text(accessory.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accessory.label,
                  style: pathLabelFont(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  owned ? '우리 집에 놓여있어요' : '${accessory.pointCost}점',
                  style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          if (owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '✓ 배치완료',
                style: pathLabelFont(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            )
          else
            _SmallButton(
              label: '구매',
              color: canAfford ? accent : AppColors.inkSoft,
              filled: canAfford,
              onTap: onBuy,
            ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _SmallButton({
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: pathLabelFont(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
