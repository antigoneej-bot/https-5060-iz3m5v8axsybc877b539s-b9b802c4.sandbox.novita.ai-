import '../../theme.dart' show AppColors;
import '../../widgets/subscription_gate.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../providers/garden_provider.dart';
import '../services/revive_service.dart';

/// "이어하기" 제안 시트.
///
/// 목숨을 다 썼을 때 뜨는 부드러운 두 번째 기회 제안 - "무한의 계단"식 핵심
/// 리텐션/수익 장치를 몽이의 다정한 톤으로 감싼다. 강요가 아니라 "선물"처럼
/// 느껴지도록, 거절해도 그동안 쌓은 결과는 그대로 인정된다는 걸 분명히 한다.
///
/// 처음 [RunnerGame.freeRevivesPerRun]번까지는 광고 없이 바로 이어갈 수
/// 있고([requiresAd]=false), 그 이후부터는 두 가지 선택지가 나란히 제시된다:
/// "광고 보고 이어하기"(무료, 시간 소요) 또는 "생명의 물로 바로 이어하기"
/// ([ReviveService.lightEssenceCost] 빛의 정수, 광고 없이 즉시). 힐링 톤은
/// 지키면서도 화폐를 가진 사용자에게는 더 빠른 대안을 준다.
///
/// 반환값: true면 이어하기로 결정한 것(무료 이어하기를 선택했거나, 광고를
/// 끝까지 보고 보상을 받았거나, 생명의 물로 즉시 구매한 경우), false(또는
/// null, 뒤로가기)면 여기서 마치기로 결정한 것.
class ReviveOfferSheet extends StatefulWidget {
  /// 이번 판에서 이미 부활을 사용한 횟수 (문구 조정용).
  final int reviveCountThisRun;

  /// true면 이번 제안은 광고를 끝까지 봐야만 이어갈 수 있다.
  /// false면 광고 없이 바로 "이어하기" 버튼 한 번으로 계속할 수 있다.
  final bool requiresAd;

  const ReviveOfferSheet({
    super.key,
    this.reviveCountThisRun = 0,
    this.requiresAd = true,
  });

  /// 부활 제안 시트를 띄운다.
  /// - [requiresAd]가 false면 "이어하기" 버튼을 누르는 즉시 true를 반환한다
  ///   (광고 없음, 무료 이어하기).
  /// - [requiresAd]가 true면 광고 시청을 끝까지 마치고 보상을 받거나, 생명의
  ///   물을 구매해야만 true를 반환한다. 그 외(거절/취소/광고 실패)에는
  ///   false를 반환한다.
  static Future<bool> show(
    BuildContext context, {
    int reviveCountThisRun = 0,
    bool requiresAd = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviveOfferSheet(
        reviveCountThisRun: reviveCountThisRun,
        requiresAd: requiresAd,
      ),
    );
    return result ?? false;
  }

  @override
  State<ReviveOfferSheet> createState() => _ReviveOfferSheetState();
}

class _ReviveOfferSheetState extends State<ReviveOfferSheet> {
  bool _watchingAd = false;
  bool _buyingRevive = false;
  bool _insufficientFunds = false;

  Future<void> _watchAd() async {
    await _buyRevive();
  }

  /// "생명의 물"로 광고 없이 즉시 부활한다. 화폐가 모자라면 안내만 하고
  /// 시트는 그대로 유지한다(다른 선택지를 고를 수 있도록).
  Future<void> _buyRevive() async {
    if (!await requestSubscription(context, message: '생명의 물 사용은 마음냥 구독에 포함돼요.'))
      return;
    if (!mounted) return;
    setState(() {
      _buyingRevive = true;
      _insufficientFunds = false;
    });
    final bought = await context
        .read<GardenProvider>()
        .buyReviveWithLightEssence();
    if (!mounted) return;
    if (bought) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _buyingRevive = false;
      _insufficientFunds = true;
    });
  }

  /// 무료 이어하기(광고 불필요) - 버튼을 누르면 곧바로 이어간다.
  void _continueFree() {
    Navigator.of(context).pop(true);
  }

  void _decline() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSecondTime = widget.reviveCountThisRun > 0;
    return SafeArea(
      top: false,
      child: PopScope(
        canPop: !_watchingAd && !_buyingRevive,
        child: Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.bg0,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_watchingAd)
                ..._buildWatchingContent(l10n)
              else if (widget.requiresAd)
                ..._buildAdOfferContent(l10n, isSecondTime)
              else
                ..._buildFreeOfferContent(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// 아직 무료 이어하기 횟수가 남아있을 때(광고 불필요) - 바로 이어갈 수
  /// 있다는 걸 강조하는, 좀 더 가벼운 톤의 제안.
  List<Widget> _buildFreeOfferContent(AppLocalizations l10n) {
    return [
      Image.asset('assets/mongi/images/cat_cry.png', height: 84),
      const SizedBox(height: 12),
      Text(
        l10n.reviveFreeOfferCountLabel(
          widget.reviveCountThisRun + 1,
          _freeRevivesLabel,
        ),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.reviveOfferHeadline,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.reviveFreeOfferBody,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.inkSoft,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _continueFree,
          icon: const Icon(Icons.favorite),
          label: Text(
            l10n.reviveContinueButton,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8FAB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _decline,
        child: Text(
          l10n.reviveDeclineButton,
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  String get _freeRevivesLabel => '3'; // RunnerGame.freeRevivesPerRun과 동일.

  /// 무료 이어하기 횟수를 다 써서 화폐/광고 중 하나를 골라야 할 때 -
  /// "광고 보고 이어하기"(무료, 시간 소요)와 "생명의 물로 즉시 이어하기"
  /// ([ReviveService.lightEssenceCost] 빛의 정수)를 나란히 제시한다.
  List<Widget> _buildAdOfferContent(AppLocalizations l10n, bool isSecondTime) {
    final lightEssence = context.watch<GardenProvider>().lightEssence;
    final cost = ReviveService.lightEssenceCost;
    final canAfford = lightEssence >= cost;
    return [
      Image.asset('assets/mongi/images/cat_cry.png', height: 84),
      const SizedBox(height: 12),
      Text(
        '이번 판의 무료 이어하기를 모두 사용했어요.',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.reviveOfferHeadline,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '여기서 마쳐도 플레이 기록은 남아요. 구독 중에는 모은 빛의 정수로 생명의 물을 사용할 수 있어요.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.inkSoft,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 20),
      // 생명의 물로 즉시 부활 (광고 없음, 화폐 소비).
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: (_buyingRevive || !canAfford) ? null : _buyRevive,
          icon: _buyingRevive
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('💧', style: TextStyle(fontSize: 18)),
          label: Text(
            l10n.reviveBuyWithLightEssenceButton(cost),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford
                ? const Color(0xFF6FB8D8)
                : const Color(0xFFCBD5DC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      if (_insufficientFunds) ...[
        const SizedBox(height: 6),
        Text(
          l10n.reviveInsufficientFunds(lightEssence, cost),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Color(0xFFE86A5B)),
        ),
      ],
      const SizedBox(height: 10),
      // 광고 보고 이어하기 (기존 무료 경로).
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _buyingRevive ? null : () => requestSubscription(context),
          icon: const Icon(Icons.play_circle_fill),
          label: Text(
            '마음냥 구독 알아보기',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF8FAB),
            side: const BorderSide(color: Color(0xFFFF8FAB), width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: (_buyingRevive || _watchingAd) ? null : _decline,
        child: Text(
          l10n.reviveDeclineButton,
          style: const TextStyle(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildWatchingContent(AppLocalizations l10n) {
    return [
      const SizedBox(height: 8),
      const Text('🎬', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 14),
      const CircularProgressIndicator(color: Color(0xFFFF8FAB)),
      const SizedBox(height: 16),
      Text(
        l10n.reviveWatchingAdTitle,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.reviveWatchingAdSubtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
      ),
      const SizedBox(height: 8),
    ];
  }
}
