import '../services/cloud_service.dart';
import 'data_safety_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import '../providers/cat_care_provider.dart';
import '../providers/promise_provider.dart';

/// '정원 플러스' 구독 안내 및 구매 화면 (페이월).
///
/// [SubscriptionService.storeBillingEnabled]가 false인 동안에는 혜택·가격은
/// 보여 주되, 구매 버튼은 비활성(준비 중)으로 두어 무료 잠금 해제를 막습니다.
/// 실결제 연동 후 플래그를 true로 바꾸면 이 화면 CTA가 구매 플로우로 이어집니다.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _sub = SubscriptionService();
  bool _isPremium = false;
  bool _loading = true;
  bool _purchasing = false;
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  SubscriptionPlan _activePlan = SubscriptionPlan.monthly;

  bool get _billingReady => SubscriptionService.storeBillingEnabled && CloudService.enabled;

  @override
  void initState() {
    super.initState();
    _load();
    AnalyticsService().logEvent(AnalyticsEvents.premiumScreenView);
  }

  Future<void> _load() async {
    await _sub.refreshProducts();
    final premium = await _sub.isPremium();
    final plan = await _sub.currentPlan();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _activePlan = plan;
      _loading = false;
    });
  }

  Future<void> _purchase() async {
    if (_purchasing) return;
    if (!_billingReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SubscriptionService.billingComingSoonCaption),
        ),
      );
      return;
    }
    setState(() => _purchasing = true);
    var ok = false;
    try {
      ok = await _sub.purchasePremium(plan: _selectedPlan);
    } catch (_) {
      ok = false;
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _isPremium = ok;
          if (ok) _activePlan = _selectedPlan;
        });
      }
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매가 완료되지 않았어요. 잠시 후 다시 확인해 주세요.')),
      );
    }
    if (ok) {
      final app = context.read<AppStateProvider>();
      final care = context.read<CatCareProvider>();
      final promise = context.read<PromiseProvider>();
      final planLabel =
          _selectedPlan == SubscriptionPlan.yearly ? 'yearly' : 'monthly';
      unawaited(() async {
        try {
          await AnalyticsService().logEvent(AnalyticsEvents.premiumPurchase, {
            'plan': planLabel,
          });
          await app.refreshPremiumStatus();
          // 케어/약속 provider의 isPremium도 즉시 맞춤
          await care.load();
          await promise.load();
        } catch (_) {}
      }());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정원 플러스 멤버십이 시작되었어요 🌷')));
    }
  }

  Future<void> _cancel() async {
    if (!SubscriptionService.storeBillingEnabled) return;
    await _sub.cancelPremium();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Play 구독 관리 화면으로 이동합니다')),
    );
  }

  Future<void> _restore() async {
    if (_purchasing) return;
    if (!SubscriptionService.storeBillingEnabled) return;
    setState(() => _purchasing = true);
    var ok = await _sub.isPremium();
    try {
      ok = await _sub.restorePurchases();
      _activePlan = await _sub.currentPlan();
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _isPremium = ok;
        });
      }
    }
    if (!mounted) return;
    {
      final app = context.read<AppStateProvider>();
      final care = context.read<CatCareProvider>();
      final promise = context.read<PromiseProvider>();
      unawaited(() async {
        try {
          await app.refreshPremiumStatus();
          await care.load();
          await promise.load();
        } catch (_) {}
      }());
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_sub.restoreUnavailable
            ? '스토어에 연결하지 못했어요. 기존 이용 상태를 유지했으니 잠시 후 다시 시도해 주세요.'
            : ok ? '구매 내역을 복원했어요' : '복원할 구독이 없어요'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '정원 플러스',
                          style: titleFont(
                            fontSize: 20,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HeroCard(
                                  isPremium: _isPremium,
                                  activePlan: _activePlan,
                                ),
                                const SizedBox(height: 18),
                                if (CloudService.enabled)
                                  TextButton(onPressed: () async {
                                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataSafetyScreen()));
                                    await _load();
                                  }, child: const Text('구매 계정 로그인·인증')),
                                if (!_isPremium) ...[
                                  _PlanSelector(
                                    selected: _selectedPlan,
                                    onChanged: (p) =>
                                        setState(() => _selectedPlan = p),
                                  ),
                                  const SizedBox(height: 18),
                                ],
                                const _FeatureList(),
                                const SizedBox(height: 24),
                                if (_isPremium) ...[
                                  Center(
                                    child: Text(
                                      '이미 정원 플러스 멤버십을 이용 중이에요 🌿',
                                      textAlign: TextAlign.center,
                                      style: bodyFont(
                                        fontSize: 13,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SecondaryButton(
                                    label: '멤버십 해지하기',
                                    onTap: _cancel,
                                  ),
                                ] else ...[
                                  _PrimaryPurchaseButton(
                                    loading: _purchasing,
                                    enabled: _billingReady,
                                    onTap: _purchase,
                                  ),
                                  if (SubscriptionService.storeBillingEnabled) ...[
                                    const SizedBox(height: 10),
                                    _SecondaryButton(
                                      label: '구매 복원',
                                      onTap: _purchasing ? () {} : _restore,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      _billingReady
                                          ? '언제든 해지할 수 있어요 · 구독은 자동 갱신됩니다'
                                          : SubscriptionService
                                              .billingComingSoonCaption,
                                      textAlign: TextAlign.center,
                                      style: bodyFont(
                                        fontSize: 11,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isPremium;
  final SubscriptionPlan activePlan;
  const _HeroCard({required this.isPremium, required this.activePlan});

  @override
  Widget build(BuildContext context) {
    final sub = SubscriptionService();
    final activeLabel = activePlan == SubscriptionPlan.yearly
        ? '현재 이용 중 ✓ (연간)'
        : '현재 이용 중 ✓ (월간)';
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: Column(
        children: [
          const Text('🌷', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 14),
          Text(
            '정원을 더 깊이\n돌아볼 수 있어요',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 21, color: AppColors.ink, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            '더 다양한 고양이를 만나고,\n주간 감정 지도를 더 깊이 들여다보세요',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          if (!isPremium) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                SubscriptionService.earlybirdLabel,
                style: bodyFont(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.blobButterAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              isPremium ? activeLabel : sub.priceLabelFor(SubscriptionPlan.monthly),
              style: numberFont(
                fontSize: 16,
                color: AppColors.blobButterAccent,
              ),
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 8),
            Text(
              SubscriptionService.earlybirdCaption,
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

/// 월간/연간 구독 플랜 선택 카드.
class _PlanSelector extends StatelessWidget {
  final SubscriptionPlan selected;
  final ValueChanged<SubscriptionPlan> onChanged;
  const _PlanSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PlanCard(
            plan: SubscriptionPlan.monthly,
            title: '월간',
            price: SubscriptionService().priceLabelFor(SubscriptionPlan.monthly),
            caption: '언제든 부담 없이',
            selected: selected == SubscriptionPlan.monthly,
            onTap: () => onChanged(SubscriptionPlan.monthly),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanCard(
            plan: SubscriptionPlan.yearly,
            title: '연간',
            price: SubscriptionService().priceLabelFor(SubscriptionPlan.yearly),
            caption: '매년 결제',
            selected: selected == SubscriptionPlan.yearly,
            onTap: () => onChanged(SubscriptionPlan.yearly),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String title;
  final String price;
  final String caption;
  final String? badge;
  final String? originalPrice;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({
    required this.plan,
    required this.title,
    required this.price,
    required this.caption,
    required this.selected,
    required this.onTap,
    this.badge,
    this.originalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blobButterAccent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.blobButterAccent
                : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: pathLabelFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: bodyFont(
                        fontSize: 9.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: selected
                      ? AppColors.blobButterAccent
                      : AppColors.inkSoft.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (originalPrice != null) ...[
              Text(
                originalPrice!,
                style: bodyFont(
                  fontSize: 11,
                  color: AppColors.inkSoft.withValues(alpha: 0.6),
                ).copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.inkSoft.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 1),
            ],
            Text(
              price,
              style: numberFont(fontSize: 16, color: AppColors.ink),
            ),
            const SizedBox(height: 3),
            Text(
              caption,
              style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _features = [
    ('🔓', '모든 감정 고양이 만나기', '자주 찾는 고양이를 즐겨찾고 필요한 감정을 골라 기록해요'),
    ('📊', '기록 패턴 살펴보기', '지난달/분기 비교, 요일·시간대 패턴, 다시 떠오른 감정까지 살펴보기'),
    ('✨', '오늘의 카드와 내 마음', '내가 고른 감정과 무작위 카드를 나란히 보는 재미용 이야기'),
    ('🧠', '감정을 돌아보는 질문', '오늘의 감정을 더 깊이 들여다보는 이야기와 질문으로 내 경험 돌아보기'),
    ('🌡️', '마음 온도 포인트 적립', '마음 온도가 100도를 넘을 때마다 포인트로 차곡차곡 쌓여요'),
    ('📊', '지난달과 감정 기록 비교', '같은 기간의 기록 횟수와 자주 고른 감정을 나란히 살펴봐요'),
    ('🌱', '주제별 실천 여정', '준비된 작은 실천을 내 속도로 이어가요'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          for (final f in _features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.$2,
                          style: pathLabelFont(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.$3,
                          style: bodyFont(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryPurchaseButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryPurchaseButton({
    required this.loading,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canTap ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.gold : AppColors.line,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.inkSoft,
          elevation: 0,
          shadowColor: AppColors.gold.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                enabled
                    ? '정원 플러스 시작하기'
                    : SubscriptionService.billingComingSoonLabel,
                style: serifFont(
                  fontSize: 15.5,
                  color: enabled ? Colors.white : AppColors.inkSoft,
                ),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkSoft,
          side: BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
        ),
      ),
    );
  }
}
