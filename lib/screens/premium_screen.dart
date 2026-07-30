import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart';
import '../providers/app_state_provider.dart';

/// '정원 플러스' 구독 안내 및 구매 화면 (페이월).
///
/// ⚠️ 실제 결제(Google Play 인앱결제)는 아직 연결되어 있지 않습니다.
/// [SubscriptionService.purchasePremium]의 주석을 참고해 개발자가 실제
/// 결제를 연동하면, 이 화면의 "구독 시작하기" 버튼이 바로 실결제로 이어집니다.
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

  @override
  void initState() {
    super.initState();
    _load();
    AnalyticsService().logEvent(AnalyticsEvents.premiumScreenView);
  }

  Future<void> _load() async {
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
    setState(() => _purchasing = true);
    final ok = await _sub.purchasePremium(plan: _selectedPlan);
    if (!mounted) return;
    setState(() {
      _purchasing = false;
      _isPremium = ok;
      if (ok) _activePlan = _selectedPlan;
    });
    if (ok) {
      await AnalyticsService().logEvent(AnalyticsEvents.premiumPurchase, {
        'plan': _selectedPlan == SubscriptionPlan.yearly ? 'yearly' : 'monthly',
      });
      if (!mounted) return;
      // 구독 상태를 앱 전역에 즉시 반영 → 재로그인/재시작 없이 바로 잠금 해제
      await context.read<AppStateProvider>().refreshPremiumStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정원 플러스 멤버십이 시작되었어요 🌷')));
    }
  }

  Future<void> _cancel() async {
    await _sub.cancelPremium();
    if (!mounted) return;
    setState(() => _isPremium = false);
    await AnalyticsService().logEvent(AnalyticsEvents.premiumCancel);
    if (!mounted) return;
    // 해지도 즉시 전역 상태에 반영
    await context.read<AppStateProvider>().refreshPremiumStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('정원 플러스 멤버십이 해지되었어요')));
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
                                    onTap: _purchase,
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      '언제든 해지할 수 있어요 · 구독은 자동 갱신됩니다',
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
            price: SubscriptionService.displayPrice,
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
            price: SubscriptionService.displayYearlyPrice,
            caption: SubscriptionService.displayYearlyMonthlyEquivalent,
            badge: SubscriptionService.yearlyDiscountLabel,
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
    ('🔓', '10마리 고양이 캐릭터 잠금 해제', '냉소·시기·서운함·두려움 등 더 섬세한 감정의 고양이를 만나보세요'),
    ('📊', '주간 그림자 지도 심층 분석', '지난달/분기 비교, 요일·시간대 패턴, 다시 떠오른 감정까지 살펴보기'),
    ('✨', '동시성(싱크로니시티) 인사이트', '내가 고른 고양이와 무의식이 고른 고양이를 비교해보는 특별한 통찰'),
    ('🧠', '심리학 박사의 그림자 해석', '오늘의 감정을 더 깊이 들여다보는 전문가 수준의 확장 해석 보기'),
    ('🌡️', '마음 온도 포인트 적립', '마음 온도가 100도를 넘을 때마다 포인트로 차곡차곡 쌓여요'),
    ('💌', '월간 리플렉션 레터', '한 달간 만난 그림자 고양이에게 답장을 남기는 특별한 마무리 의식'),
    ('🌱', '더 섬세한 감정 여정', '52마리 고양이를 모두 만나며 놓치기 쉬운 감정까지 세심하게 돌보기'),
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
  final VoidCallback onTap;
  const _PrimaryPurchaseButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
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
                '정원 플러스 시작하기',
                style: serifFont(fontSize: 15.5, color: Colors.white),
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
