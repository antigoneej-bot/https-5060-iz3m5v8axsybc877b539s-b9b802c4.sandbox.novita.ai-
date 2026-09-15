import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/purchase_l10n.dart';
import '../l10n/season_reward_l10n.dart';
import '../models/season_pass.dart';
import '../providers/garden_provider.dart';
import '../services/purchase_service.dart';

/// 시즌 패스("몽이의 마음여정") 화면.
///
/// F2P 표준 시즌 패스 UI: 게임 플레이 + 매일 체크인 + 감사/성취 기록으로
/// 쌓이는 시즌 경험치로 레벨이 오르고, 무료/프리미엄 두 트랙에서 각 레벨의
/// 보상을 "수령"한다. 프리미엄 트랙은 구매 전에도 미리 보여줘서(잠금 표시)
/// 소유욕을 자극하고, 카운트다운으로 시즌이 유한하다는 긴급성을 전달한다.
///
/// "1번 개선": 5의 배수 레벨(5/10/15/20)은 [SeasonPass.isMindMilestone]으로
/// "마음 마일스톤"으로 표시해, 순수 재화 수집 트랙이 아니라 "꾸준히 마음을
/// 돌본 여정"이라는 톤을 함께 전달한다.
class SeasonPassScreen extends StatefulWidget {
  const SeasonPassScreen({super.key});

  @override
  State<SeasonPassScreen> createState() => _SeasonPassScreenState();
}

class _SeasonPassScreenState extends State<SeasonPassScreen> {
  bool _purchasing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<GardenProvider>().refreshSeasonPass();
      _scrollToCurrentLevel();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLevel() {
    if (!mounted || !_scrollController.hasClients) return;
    final garden = context.read<GardenProvider>();
    final target = (garden.seasonLevel - 1).clamp(0, SeasonPass.maxLevel - 1);
    // 카드 하나(가로 폭 132 + 마진 10) 기준으로 대략적인 위치까지 스크롤.
    final offset = (target * 142.0 - 60).clamp(
      0.0,
      _scrollController.position.hasContentDimensions
          ? _scrollController.position.maxScrollExtent
          : 99999.0,
    );
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  String _formatCountdown(AppLocalizations l10n, int seconds) {
    final s = seconds.clamp(0, 999999999);
    final d = s ~/ 86400;
    final h = (s % 86400) ~/ 3600;
    final m = (s % 3600) ~/ 60;
    if (d > 0) return l10n.seasonPassCountdownDays(d, h);
    if (h > 0) return l10n.seasonPassCountdownHours(h, m);
    return l10n.seasonPassCountdownMinutes(m);
  }

  Future<void> _showPurchaseConfirm() async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.seasonPassPurchaseDialogTitle),
        content: Text(l10n.seasonPassPurchaseDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.sharePremiumDialogLater),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFA36BE0),
            ),
            child: Text(l10n.sharePremiumDialogBuy),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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

    final submitted = await garden.buySeasonPassPremium();
    if (!mounted) return;
    if (!submitted) {
      setState(() => _purchasing = false);
    } else {
      Future<void>.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _purchasing = false);
      });
    }
  }

  Future<void> _onRestore() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _purchasing = true);
    await context.read<GardenProvider>().restoreSeasonPassPurchase();
    if (!mounted) return;
    setState(() => _purchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.seasonPassRestoreConfirmedSnackbar)),
    );
  }

  Future<void> _claimFree(int level) async {
    final l10n = AppLocalizations.of(context);
    final ok = await context.read<GardenProvider>().claimSeasonFreeReward(
      level,
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.seasonPassFreeRewardClaimedSnackbar(level))),
    );
  }

  Future<void> _claimPremium(int level) async {
    final l10n = AppLocalizations.of(context);
    final ok = await context.read<GardenProvider>().claimSeasonPremiumReward(
      level,
    );
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.seasonPassPremiumRewardClaimedSnackbar(level)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.seasonPassAppBarTitle(garden.seasonNumber),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildHeader(l10n, garden),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l10n.seasonPassSubHeadline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ),
          Expanded(child: _buildTierList(l10n, garden)),
          _buildBottomBar(l10n, garden),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, GardenProvider garden) {
    final level = garden.seasonLevel;
    final xpInto = garden.seasonXpIntoLevel;
    final span = garden.seasonXpSpanForLevel;
    final progress = span == 0 ? 1.0 : (xpInto / span).clamp(0.0, 1.0);
    final isMax = level >= SeasonPass.maxLevel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE0A3), Color(0xFFFFC98F)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text('🌱', style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMax
                            ? l10n.seasonPassLevelLabelMax(level)
                            : l10n.seasonPassLevelLabel(level),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Color(0xFF6B4A1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⏳ ${_formatCountdown(l10n, garden.seasonSecondsRemaining)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8A5A1F),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!garden.seasonPremiumPurchased)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA36BE0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.seasonPassFreeTierBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4C7A44),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      l10n.seasonPassPremiumTierBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.55),
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMax
                  ? l10n.seasonPassMaxLevelReached
                  : l10n.seasonPassXpProgress(xpInto, span),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A5A1F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierList(AppLocalizations l10n, GardenProvider garden) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: SeasonPass.tiers.length,
      itemBuilder: (context, index) {
        final tier = SeasonPass.tiers[index];
        return _tierCard(l10n, garden, tier);
      },
    );
  }

  Widget _tierCard(
    AppLocalizations l10n,
    GardenProvider garden,
    SeasonPassTier tier,
  ) {
    final level = tier.level;
    final reached = garden.seasonLevel >= level;
    final freeClaimed = garden.seasonClaimedFreeLevels.contains(level);
    final premiumClaimed = garden.seasonClaimedPremiumLevels.contains(level);
    final isCurrent = garden.seasonLevel + 1 == level;
    // "1번 개선": 5의 배수 레벨은 "마음 마일스톤"으로 표시해, 이 카드가
    // 단순 재화 슬롯이 아니라 꾸준함을 기념하는 지점임을 알려준다.
    final isMindMilestone = SeasonPass.isMindMilestone(level);

    return Container(
      width: 132,
      margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMindMilestone ? const Color(0xFFF3F9F0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFFF8FAB)
              : isMindMilestone
              ? const Color(0xFF7FB37A).withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.06),
          width: isCurrent || isMindMilestone ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isMindMilestone)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.seasonPassMindMilestoneBadge,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4C7A44),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: reached ? const Color(0xFFFFE0A3) : AppColors.catSageBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.seasonPassTierLevelLabel(level),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: reached ? const Color(0xFF8A5A1F) : AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _rewardSlot(
            l10n: l10n,
            reward: tier.free,
            reached: reached,
            claimed: freeClaimed,
            unlockedTrack: true,
            onClaim: reached && !freeClaimed ? () => _claimFree(level) : null,
          ),
          const SizedBox(height: 8),
          _rewardSlot(
            l10n: l10n,
            reward: tier.premium,
            reached: reached,
            claimed: premiumClaimed,
            unlockedTrack: garden.seasonPremiumPurchased,
            onClaim: reached && !premiumClaimed && garden.seasonPremiumPurchased
                ? () => _claimPremium(level)
                : null,
            isPremium: true,
          ),
        ],
      ),
    );
  }

  Widget _rewardSlot({
    required AppLocalizations l10n,
    required SeasonRewardItem reward,
    required bool reached,
    required bool claimed,
    required bool unlockedTrack,
    required VoidCallback? onClaim,
    bool isPremium = false,
  }) {
    final locked = !unlockedTrack;
    return GestureDetector(
      onTap: onClaim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: claimed
              ? const Color(0xFFE8F5E0)
              : isPremium
              ? const Color(0xFFF3E8FF)
              : const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPremium
                ? const Color(0xFFA36BE0).withValues(alpha: 0.35)
                : const Color(0xFFE0A93A).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: locked ? 0.45 : 1.0,
              child: Text(reward.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: locked ? 0.45 : 1.0,
              child: Text(
                seasonRewardLabel(l10n, reward),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (locked)
              const Icon(Icons.lock, size: 14, color: AppColors.inkSoft)
            else if (claimed)
              const Icon(Icons.check_circle, size: 16, color: Color(0xFF4C7A44))
            else if (reached)
              Text(
                l10n.seasonPassClaimButton,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB1466E),
                ),
              )
            else
              const Icon(Icons.lock_clock, size: 14, color: Color(0xFFBBB0A6)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n, GardenProvider garden) {
    if (garden.seasonPremiumPurchased) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E0),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            l10n.seasonPassOwnedBanner,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF4C7A44),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _purchasing ? null : _showPurchaseConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA36BE0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _purchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      l10n.seasonPassUpgradeButton,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _purchasing ? null : _onRestore,
            child: Text(
              l10n.shareRestorePurchaseButton,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}
