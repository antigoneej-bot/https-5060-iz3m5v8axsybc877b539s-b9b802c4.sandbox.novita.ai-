import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/mongi_care_item_l10n.dart';
import '../models/mongi_care_item.dart';
import '../providers/garden_provider.dart';

/// "몽이 돌봄 세트" 바텀시트 - 참치캔/사료/맑은물 같은 소모품을 빛의 정수로
/// 사서 몽이에게 직접 줄 수 있고, 담요/몽이의 집 같은 특별한 선물은 한 번
/// 사면 정원에 영구히 자리 잡는다.
///
/// [MongiCareItem.all]을 그대로 순회해서 그리므로 새 돌봄 아이템을 추가해도
/// 이 화면 코드는 수정할 필요가 없다(장식/파워부적 상점과 동일한 설계 원칙).
class MongiCareSheet extends StatefulWidget {
  const MongiCareSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MongiCareSheet(),
    );
  }

  @override
  State<MongiCareSheet> createState() => _MongiCareSheetState();
}

class _MongiCareSheetState extends State<MongiCareSheet> {
  bool _busy = false;

  Future<void> _give(MongiCareItem item) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final garden = context.read<GardenProvider>();
    final result = await garden.giveMongiCareItem(item);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) {
      _showSnack(l10n.mongiCareNotEnoughSnackbar);
      return;
    }
    final reaction = mongiCareItemReactionMessage(l10n, result.item);
    _showSnack(
      result.isNewKeepsake
          ? l10n.mongiCareKeepsakePlacedSuffix(reaction)
          : reaction,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final consumables = MongiCareItem.all
        .where((i) => i.type == MongiCareItemType.consumable)
        .toList();
    final keepsakes = MongiCareItem.all
        .where((i) => i.type == MongiCareItemType.keepsake)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFBF6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.mongiCareSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              _currencyRow(l10n, garden),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    _sectionLabel(l10n.mongiCareConsumableSectionLabel),
                    const SizedBox(height: 8),
                    ...consumables.map((i) => _careTile(l10n, garden, i)),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.mongiCareKeepsakeSectionLabel),
                    const SizedBox(height: 8),
                    ...keepsakes.map((i) => _careTile(l10n, garden, i)),
                    if (_busy) const SizedBox(height: 8),
                    if (_busy) const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _currencyRow(AppLocalizations l10n, GardenProvider garden) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('💡', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          l10n.mongiCareLightEssenceLabel(garden.lightEssence),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A6D1F),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.inkSoft,
    ),
  );

  Widget _careTile(
    AppLocalizations l10n,
    GardenProvider garden,
    MongiCareItem item,
  ) {
    final count = garden.mongiCareCountFor(item);
    final owned = item.isKeepsake && count > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (_busy || owned) ? null : () => _give(item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: owned
                ? const Color(0xFFE8F5E0)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: owned
                  ? const Color(0xFF7FB37A)
                  : Colors.black.withValues(alpha: 0.06),
              width: owned ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mongiCareItemName(l10n, item),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      owned
                          ? l10n.mongiCareKeepsakePlacedStatus
                          : (item.isKeepsake
                                ? l10n.mongiCareKeepsakeHint
                                : (count > 0
                                      ? l10n.mongiCareGivenCountStatus(count)
                                      : l10n.mongiCareNeverGivenStatus)),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!owned)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '💡${item.lightEssenceCost}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A6D1F),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF7FB37A),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
