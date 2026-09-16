import '../../widgets/subscription_gate.dart';
import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/garden_decoration_l10n.dart' as garden_deco_l10n;
import '../l10n/gen/app_localizations.dart';
import '../models/garden_decoration.dart';
import '../providers/garden_provider.dart';

/// "정원 꾸미기" 바텀시트 - [GardenDecoration.all]을 그대로 순회해서 그리므로
/// 새 장식 아이템을 추가해도 이 화면 코드는 수정할 필요가 없다.
/// - 무료 아이템: 마일스톤을 달성하면 잠금 해제 -> 탭해서 장착/해제
/// - 프리미엄 아이템: 정원 장식팩을 구매하면 3종 모두 한 번에 잠금 해제
void showGardenDecorationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GardenDecorationSheet(),
  );
}

class GardenDecorationSheet extends StatefulWidget {
  const GardenDecorationSheet({super.key});

  @override
  State<GardenDecorationSheet> createState() => _GardenDecorationSheetState();
}

class _GardenDecorationSheetState extends State<GardenDecorationSheet> {
  bool _purchasing = false;

  /// [GardenProvider]는 AppLocalizations에 의존하지 않으므로, 원시 상태를
  /// 넘겨 다국어 진행 문구를 조립하는 것은 이 화면(UI 계층)의 책임이다.
  String? _progressLabel(
    AppLocalizations l10n,
    GardenProvider garden,
    GardenDecoration deco,
  ) {
    return garden_deco_l10n.decorationProgressLabel(
      l10n,
      decoration: deco,
      isUnlocked: garden.isDecorationUnlocked(deco),
      streakDays: garden.streakDays,
      progress: garden.progress,
      seedCounts: garden.seedCounts,
    );
  }

  Future<void> _onTapDecoration(GardenDecoration deco) async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    await garden.refreshSubscription();
    if (!mounted) return;
    if (garden.isDecorationUnlocked(deco)) {
      await garden.toggleDecorationEquipped(deco);
      return;
    }
    if (deco.isPremium) {
      await _showPurchaseConfirm();
    } else {
      final progress = _progressLabel(l10n, garden, deco);
      final hint = garden_deco_l10n.decorationUnlockHint(l10n, deco);
      _showSnack(
        progress == null
            ? hint
            : l10n.gardenDecoUnlockHintWithProgress(hint, progress),
      );
    }
  }

  Future<void> _showPurchaseConfirm() async {
    await requestSubscription(context);
    if (!mounted) return;
    await context.read<GardenProvider>().refreshSubscription();
  }

  Future<void> _onRestore() async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    setState(() => _purchasing = true);
    await garden.restoreDecorationPackPurchase();
    if (!mounted) return;
    setState(() => _purchasing = false);
    _showSnack(l10n.seasonPassRestoreConfirmedSnackbar);
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
                l10n.gardenDecoSheetTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.gardenDecoSheetSubtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    _sectionLabel(l10n.gardenDecoFreeSectionLabel),
                    const SizedBox(height: 8),
                    ...GardenDecoration.all
                        .where((d) => !d.isPremium)
                        .map((d) => _decorationTile(garden, d, l10n)),
                    const SizedBox(height: 20),
                    _sectionLabel(l10n.gardenDecoPremiumSectionLabel),
                    const SizedBox(height: 8),
                    ...GardenDecoration.all
                        .where((d) => d.isPremium)
                        .map((d) => _decorationTile(garden, d, l10n)),
                    const SizedBox(height: 12),
                    if (!garden.decorationPackUnlocked)
                      Center(
                        child: TextButton(
                          onPressed: _purchasing ? null : _onRestore,
                          child: Text(l10n.gardenDecoRestoreButton),
                        ),
                      ),
                    if (_purchasing) const SizedBox(height: 8),
                    if (_purchasing)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

  Widget _decorationTile(
    GardenProvider garden,
    GardenDecoration deco,
    AppLocalizations l10n,
  ) {
    final unlocked = garden.isDecorationUnlocked(deco);
    final equipped = garden.isDecorationEquipped(deco);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onTapDecoration(deco),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: equipped
                ? const Color(0xFFE8F5E0)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: equipped
                  ? const Color(0xFF7FB37A)
                  : Colors.black.withValues(alpha: 0.06),
              width: equipped ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Opacity(
                  opacity: unlocked ? 1.0 : 0.35,
                  child: Text(deco.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          garden_deco_l10n.decorationLabel(l10n, deco),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink,
                          ),
                        ),
                        if (deco.isPremium) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE0B2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.gardenDecoProBadge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB26A00),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      unlocked
                          ? (equipped
                                ? l10n.gardenDecoEquippedStatus
                                : l10n.gardenDecoTapToPlaceStatus)
                          : garden_deco_l10n.decorationUnlockHint(l10n, deco),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    if (!unlocked &&
                        _progressLabel(l10n, garden, deco) != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.gardenDecoProgressBadge(
                            _progressLabel(l10n, garden, deco)!,
                          ),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB26A00),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                unlocked
                    ? (equipped
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked)
                    : Icons.lock_outline,
                color: unlocked
                    ? const Color(0xFF7FB37A)
                    : Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
