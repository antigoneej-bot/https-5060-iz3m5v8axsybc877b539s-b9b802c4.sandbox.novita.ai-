import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/power_item.dart';
import '../providers/garden_provider.dart';

/// "파워 부적" 구매 바텀시트 - 게임 화면에서 부적이 부족할 때(또는 미리
/// 더 사두고 싶을 때) 언제든 열 수 있다. [MindBoxScreen]의 "마음 상자"와
/// 동일한 F2P 설계(확률 없음, 화폐를 내면 확정으로 인벤토리에 쌓임)를
/// 그대로 따른다.
class PowerCharmShopSheet extends StatefulWidget {
  const PowerCharmShopSheet({super.key});

  /// 시트를 띄운다. 게임이 잠시 멈춰 있는 동안(러너 게임 화면에서
  /// pauseEngine 후 호출) 사용하는 것을 권장한다.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PowerCharmShopSheet(),
    );
  }

  @override
  State<PowerCharmShopSheet> createState() => _PowerCharmShopSheetState();
}

class _PowerCharmShopSheetState extends State<PowerCharmShopSheet> {
  bool _buying = false;

  Future<void> _buyOne() async {
    if (_buying) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _buying = true);
    final garden = context.read<GardenProvider>();
    final ok = await garden.buyPowerCharm();
    setState(() => _buying = false);
    if (!mounted) return;
    if (!ok) {
      _showNotEnough();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.powerCharmBoughtOneSnackbar),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _buyBulk() async {
    if (_buying) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _buying = true);
    final garden = context.read<GardenProvider>();
    final ok = await garden.buyPowerCharmBulk();
    setState(() => _buying = false);
    if (!mounted) return;
    if (!ok) {
      _showNotEnough();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.powerCharmBoughtBulkSnackbar(PowerCharmOffer.bulkQuantity),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showNotEnough() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.powerCharmNotEnoughSnackbar),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final oneCost = PowerCharmOffer.lightEssenceCost;
    final bulkCount = PowerCharmOffer.bulkQuantity;
    final bulkCost = oneCost * bulkCount;
    final canOne = garden.lightEssence >= oneCost;
    final canBulk = garden.lightEssence >= bulkCost;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0A3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('⚡', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.powerCharmTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.powerCharmDescription(garden.powerCharmCount),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    '${garden.lightEssence}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF8A6D1F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buyButton(
                    label: l10n.powerCharmBuyOneLabel,
                    cost: oneCost,
                    enabled: canOne && !_buying,
                    onTap: _buyOne,
                    filled: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buyButton(
                    label: l10n.powerCharmBuyBulkLabel(bulkCount),
                    cost: bulkCost,
                    enabled: canBulk && !_buying,
                    onTap: _buyBulk,
                    filled: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.commonCloseButton,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buyButton({
    required String label,
    required int cost,
    required bool enabled,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return SizedBox(
      height: 62,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled
              ? const Color(0xFFFFC93C)
              : Colors.white.withValues(alpha: 0.9),
          foregroundColor: filled ? Colors.white : AppColors.ink,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: filled ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE7DECF)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              '💡 $cost',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: filled
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
