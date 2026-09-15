import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/light_essence_pack_l10n.dart';
import '../l10n/purchase_l10n.dart';
import '../models/light_essence_pack.dart';
import '../providers/garden_provider.dart';
import '../services/purchase_service.dart';

/// "빛의 정수 충전" 바텀시트 - 실제 결제(원화)로 빛의 정수를 직접 채워준다.
/// [PowerCharmShopSheet]과 달리 여기서 소비하는 화폐는 빛의 정수가 아니라
/// 실제 돈이므로, [SeasonPassScreen]과 같은 실제 IAP 흐름
/// (onPurchaseMessage/onPurchasePending 콜백 연동)을 따른다.
class LightEssenceShopSheet extends StatefulWidget {
  const LightEssenceShopSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LightEssenceShopSheet(),
    );
  }

  @override
  State<LightEssenceShopSheet> createState() => _LightEssenceShopSheetState();
}

class _LightEssenceShopSheetState extends State<LightEssenceShopSheet> {
  bool _purchasing = false;

  Future<void> _buy(LightEssencePack pack) async {
    if (_purchasing) return;
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();

    setState(() => _purchasing = true);
    PurchaseService.instance.onPurchaseMessage = (message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(purchaseMessageText(l10n, message))),
      );
      setState(() => _purchasing = false);
    };
    PurchaseService.instance.onPurchasePending = () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sharePurchaseProcessingSnackbar)),
      );
    };

    final submitted = await garden.buyLightEssencePack(pack);
    if (!mounted) return;
    if (!submitted) {
      setState(() => _purchasing = false);
    } else {
      // 실제 지급은 구매 확인 콜백(_grantLightEssencePack)에서 비동기로
      // 이뤄지므로, 여기서는 버튼 잠금을 잠시 후 풀어준다.
      Future<void>.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _purchasing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final packs = LightEssencePack.all;
    // 단가(100개당 가격)가 가장 낮은 팩을 "이득" 배지로 표시한다.
    final bestValueId = packs
        .reduce((a, b) => a.pricePer100 <= b.pricePer100 ? a : b)
        .productId;

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
                    color: const Color(0xFFFFE9A3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('💡', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.lightEssenceShopTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.lightEssenceShopDescription(garden.lightEssence),
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
            ...packs.map(
              (pack) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _packTile(
                  l10n: l10n,
                  pack: pack,
                  isBestValue: pack.productId == bestValueId,
                  enabled: !_purchasing,
                  onTap: () => _buy(pack),
                ),
              ),
            ),
            TextButton(
              onPressed: _purchasing ? null : () => Navigator.of(context).pop(),
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

  Widget _packTile({
    required AppLocalizations l10n,
    required LightEssencePack pack,
    required bool isBestValue,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isBestValue
                  ? const Color(0xFFFFC93C)
                  : const Color(0xFFE7DECF),
              width: isBestValue ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          lightEssencePackLabel(l10n, pack),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (isBestValue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC93C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.lightEssenceShopBestValueBadge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.lightEssenceShopPackAmountPrice(
                        pack.amount,
                        pack.pricePer100.toStringAsFixed(0),
                      ),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFFFC93C)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '₩${pack.priceKrw}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: enabled ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
