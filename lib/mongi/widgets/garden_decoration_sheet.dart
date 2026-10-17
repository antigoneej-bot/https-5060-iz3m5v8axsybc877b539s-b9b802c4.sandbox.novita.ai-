import '../../widgets/subscription_gate.dart';
import '../../screens/account_screen.dart';
import '../../services/subscription_service.dart';
import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/garden_decoration_l10n.dart' as garden_deco_l10n;
import '../l10n/gen/app_localizations.dart';
import '../models/garden_decoration.dart';
import '../providers/garden_provider.dart';

/// "정원 꾸미기" 바텀시트 - [GardenDecoration.all]을 그대로 순회해서 그리므로
/// 새 장식 아이템을 추가해도 이 화면 코드는 수정할 필요가 없다.
/// - 기본 장식: 기록·명상으로 모은 빛의 정수 60개로 받아 배치한다.
/// - 구독 장식: 구독 권한을 확인하고 받은 뒤 계속 소유한다.
/// 이전에 획득하거나 잠금 해제한 장식은 그대로 사용할 수 있다.
void showGardenDecorationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GardenDecorationSheet(),
  );
}

class GardenDecorationSheet extends StatefulWidget {
  const GardenDecorationSheet({
    super.key,
    this.ensureSignedIn = AccountScreen.ensureSignedIn,
  });

  final Future<bool> Function(BuildContext) ensureSignedIn;

  @override
  State<GardenDecorationSheet> createState() => _GardenDecorationSheetState();
}

class _GardenDecorationSheetState extends State<GardenDecorationSheet> {
  bool _purchasing = false;

  String _status(GardenProvider garden, GardenDecoration deco) {
    if (garden.isDecorationUnlocked(deco)) {
      return garden.isDecorationEquipped(deco)
          ? '정원에 놓여 있어요 · 눌러서 보관'
          : '사용할 수 있어요 · 눌러서 배치';
    }
    return deco.isPremium
        ? '구독자를 위한 선물 · 한 번 받으면 계속 소유해요'
        : '빛의 정수 60개 · 눌러서 받고 배치';
  }

  Future<void> _onTapDecoration(GardenDecoration deco) async {
    if (_purchasing) return;
    final garden = context.read<GardenProvider>();
    setState(() => _purchasing = true);
    try {
      await garden.refreshSubscription();
      if (!mounted) return;
      if (garden.isDecorationUnlocked(deco)) {
        await garden.toggleDecorationEquipped(deco);
      } else if (deco.isPremium) {
        await _showPurchaseConfirm();
      } else {
        await garden.obtainDecoration(deco);
        if (mounted) _showSnack('${deco.label}을 정원에 놓았어요.');
      }
    } catch (error) {
      if (mounted) {
        _showSnack(
          error is StateError ? error.message : '장식을 저장하지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _showPurchaseConfirm() async {
    await requestSubscription(context);
    if (!mounted) return;
    await context.read<GardenProvider>().refreshSubscription();
  }

  Future<void> _onRestore() async {
    if (_purchasing) return;
    final garden = context.read<GardenProvider>();
    setState(() => _purchasing = true);
    try {
      if (!await widget.ensureSignedIn(context) || !mounted) return;
      final result = await garden.restoreDecorationPackPurchase();
      if (mounted) _showSnack(result.message);
    } catch (_) {
      if (mounted) {
        _showSnack(
          const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.unavailable,
          ).message,
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '빛의 정수 ${garden.lightEssence}개 · 기록이나 명상을 마치면 하루 한 번 20개를 받아요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    _sectionLabel('기본 장식 · 빛의 정수로 꾸미기'),
                    const SizedBox(height: 8),
                    ...GardenDecoration.all
                        .where((d) => !d.isPremium)
                        .map((d) => _decorationTile(garden, d, l10n)),
                    const SizedBox(height: 20),
                    _sectionLabel('구독자 정원 선물'),
                    const SizedBox(height: 8),
                    ...GardenDecoration.all
                        .where((d) => d.isPremium)
                        .map((d) => _decorationTile(garden, d, l10n)),
                    const SizedBox(height: 12),
                    if (!garden.decorationPackUnlocked)
                      Center(
                        child: TextButton(
                          onPressed: _purchasing ? null : _onRestore,
                          child: const Text('구독 복원하기'),
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
        onTap: _purchasing ? null : () => _onTapDecoration(deco),
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
                      _status(garden, deco),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                unlocked
                    ? (equipped
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked)
                    : (deco.isPremium
                          ? Icons.lock_outline
                          : Icons.add_circle_outline),
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
