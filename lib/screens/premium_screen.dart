import '../l10n/app_language.dart';
import '../utils/feature_flags.dart';
import '../widgets/premium_test_access.dart';
import '../mongi/services/ad_service.dart';
import '../services/cloud_service.dart';
import 'account_screen.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../mongi/providers/garden_provider.dart';

/// The screen's billing boundary also lets widget tests exercise delayed store
/// and account results without contacting a real billing or login service.
@visibleForTesting
class PremiumScreenBilling {
  final _subscription = SubscriptionService();

  String? get currentUid => CloudService.currentUser?.uid;
  bool get backendEnabled => CloudService.enabled;
  bool get supportedStore =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool hasProduct(SubscriptionPlan plan) => _subscription.hasProduct(plan);
  String priceLabelFor(SubscriptionPlan plan) =>
      _subscription.priceLabelFor(plan);
  String offerLabelFor(SubscriptionPlan plan) =>
      _subscription.offerLabelFor(plan);
  Future<void> refreshProducts() => _subscription.refreshProducts();
  String productAvailabilityLabel(SubscriptionPlan plan) =>
      _subscription.productAvailabilityLabel(plan);
  Future<void> refreshStatus(String owner) async {
    await CloudService.refreshEntitlement(expectedUid: owner);
  }

  Future<bool> isPremium() => _subscription.isPremium();
  Future<SubscriptionPlan?> currentPlan() => _subscription.currentPlanIfKnown();
  Future<String> statusLabel() => CloudService.subscriptionStatusLabel();
  Future<bool> ensureSignedIn(BuildContext context) =>
      AccountScreen.ensureSignedIn(context);
  Future<bool> purchase(SubscriptionPlan plan) =>
      _subscription.purchasePremium(plan: plan);
  Future<bool> changeToYearly() => _subscription.purchasePremium(
    plan: SubscriptionPlan.yearly,
    replaceMonthly: true,
  );
  Future<SubscriptionRestoreResult> restore() =>
      _subscription.restorePurchasesWithResult();
  Future<void> cancel() => _subscription.cancelPremium();
  Future<void> logPurchase(SubscriptionPlan plan) =>
      AnalyticsService().logEvent(AnalyticsEvents.premiumPurchase, {
        'plan': plan == SubscriptionPlan.yearly ? 'yearly' : 'monthly',
      });
}

/// '마음냥 구독' 구독 안내 및 구매 화면 (페이월).
///
/// [SubscriptionService.storeBillingEnabled]가 false인 동안에는 혜택·가격은
/// 보여 주되, 구매 버튼은 비활성(준비 중)으로 두어 무료 잠금 해제를 막습니다.
/// 실결제 연동 후 플래그를 true로 바꾸면 이 화면 CTA가 구매 플로우로 이어집니다.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.billing});

  @visibleForTesting
  final PremiumScreenBilling? billing;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with WidgetsBindingObserver {
  late final _billing = widget.billing ?? PremiumScreenBilling();
  bool _isPremium = false;
  String _statusLabel = tr("무료 이용 중");
  bool _loading = true;
  bool _purchasing = false;
  bool _refreshingStatus = false;
  bool _awaitingManagementReturn = false;
  String? _managementOwner;
  int _loadGeneration = 0;
  String? _displayOwner;
  SubscriptionPlan _selectedPlan = SubscriptionPlan.yearly;
  SubscriptionPlan? _activePlan;

  bool get _supportedStore => _billing.supportedStore;

  bool get _billingReady =>
      _supportedStore &&
      SubscriptionService.storeBillingEnabled &&
      _billing.backendEnabled &&
      _billing.hasProduct(_selectedPlan);

  String get _billingCaption {
    if (!_supportedStore) {
      return tr("구독 구매와 복원은 Google Play에서 설치한 Android 앱에서 이용할 수 있어요.");
    }
    if (!SubscriptionService.storeBillingEnabled || !_billing.backendEnabled) {
      return SubscriptionService.billingComingSoonCaption;
    }
    if (!_billing.hasProduct(_selectedPlan)) {
      return _billing.productAvailabilityLabel(_selectedPlan);
    }
    return tr("언제든 해지할 수 있어요 · 구독은 자동 갱신됩니다");
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    unawaited(
      AnalyticsService()
          .logEvent(AnalyticsEvents.premiumScreenView)
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingManagementReturn) {
      _awaitingManagementReturn = false;
      if (_billing.currentUid == _managementOwner) {
        unawaited(_refreshSubscriptionStatus());
      } else {
        unawaited(_load());
      }
    }
  }

  Future<void> _refreshSubscriptionStatus() async {
    if (_refreshingStatus) return;
    final owner = _billing.currentUid;
    if (owner == null) return;
    setState(() => _refreshingStatus = true);
    try {
      await _billing.refreshStatus(owner);
      if (!_sameOwner(owner)) return;
      final active = await _billing.isPremium();
      if (!_sameOwner(owner)) return;
      final plan = await _billing.currentPlan();
      if (!_sameOwner(owner)) return;
      final status = await _billing.statusLabel();
      if (!_sameOwner(owner)) return;
      setState(() {
        _isPremium = active;
        _activePlan = plan;
        _displayOwner = owner;
        _statusLabel = status;
      });
      _applyPremium(active);
    } catch (_) {
      if (mounted && _sameOwner(owner)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr("최신 구독 상태를 확인하지 못했어요. 기존 이용 상태는 유지돼요. 잠시 후 다시 확인해 주세요."),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingStatus = false);
        if (!_sameOwner(owner)) await _load();
      }
    }
  }

  bool _sameOwner(String? owner) => mounted && _billing.currentUid == owner;

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final owner = _billing.currentUid;
    bool isCurrent() =>
        mounted && generation == _loadGeneration && _sameOwner(owner);
    if (mounted) {
      setState(() {
        _loading = true;
        if (_displayOwner != owner) {
          _isPremium = false;
          _activePlan = null;
          _statusLabel = tr("무료 이용 중");
          _displayOwner = owner;
        }
      });
    }
    try {
      if (_supportedStore) await _billing.refreshProducts();
      if (!isCurrent()) return;
      final premium = await _billing.isPremium();
      if (!isCurrent()) return;
      final plan = await _billing.currentPlan();
      if (!isCurrent()) return;
      final statusLabel = await _billing.statusLabel();
      if (!isCurrent()) return;
      setState(() {
        _isPremium = premium;
        _activePlan = plan;
        _statusLabel = statusLabel;
      });
    } catch (_) {
      if (isCurrent()) {
        setState(() => _statusLabel = tr("이용 상태를 확인하지 못했어요. 다시 확인해 주세요."));
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        if (_sameOwner(owner)) {
          setState(() => _loading = false);
        } else {
          // A different account must get its own snapshot, never this result.
          unawaited(_load());
        }
      }
    }
  }

  void _applyPremium(bool active) {
    context.read<AppStateProvider>().setAccountPremium(active);
    context.read<CatCareProvider>().setAccountPremium(active);
    context.read<PromiseProvider>().setAccountPremium(active);
    context.read<GardenProvider>().setAccountPremium(active);
  }

  Future<void> _changeToYearly() async {
    final owner = _billing.currentUid;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("연간 구독으로 바꿀까요?")),
        content: Text(
          tr(
            "연간 {0}를 지금 결제하는 방식이에요. 남은 월간 이용분은 Google Play가 새 이용 기간에 반영해요. 최종 금액과 다음 결제일을 Play 결제 화면에서 확인한 뒤 승인해 주세요. 기존 월간 구독을 대체하며, 취소하면 현재 구독이 유지돼요.",
            [_billing.priceLabelFor(SubscriptionPlan.yearly)],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("돌아가기")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr("Play에서 확인")),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !_sameOwner(owner)) return;
    setState(() => _selectedPlan = SubscriptionPlan.yearly);
    await _purchase(replaceMonthly: true);
  }

  Future<void> _purchase({bool replaceMonthly = false}) async {
    if (_purchasing) return;
    if (!_billingReady) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_billingCaption)));
      return;
    }
    ++_loadGeneration;
    setState(() => _purchasing = true);
    final initialOwner = _billing.currentUid;
    String? owner;
    try {
      if (!await _billing.ensureSignedIn(context) || !mounted) return;
      owner = _billing.currentUid;
      if (owner == null) return;
      final plan = _selectedPlan;
      final ok = await (replaceMonthly
          ? _billing.changeToYearly()
          : _billing.purchase(plan));
      if (!mounted || !_sameOwner(owner)) return;
      if (!ok) {
        // A cancelled/failed new transaction does not revoke existing access.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("구매가 완료되지 않았어요. 잠시 후 다시 확인해 주세요."))),
        );
        return;
      }
      var statusLabel = tr("마음냥 구독 이용 중");
      try {
        statusLabel = await _billing.statusLabel();
      } catch (_) {
        // Store verification already succeeded; a label lookup is optional.
      }
      if (!mounted || !_sameOwner(owner)) return;
      setState(() {
        _isPremium = true;
        _displayOwner = owner;
        _activePlan = plan;
        _statusLabel = statusLabel;
      });
      // Access is applied now, without waiting for optional analytics. There is
      // no asynchronous gap between the owner check and these provider writes.
      _applyPremium(true);
      unawaited(_billing.logPurchase(plan).catchError((Object _) {}));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("마음냥 구독 멤버십이 시작되었어요 🌷"))));
    } on CloudException catch (error) {
      final expectedOwner = owner ?? initialOwner;
      if (!mounted || !_sameOwner(expectedOwner)) return;
      if (error.code == 'subscription-already-active') {
        // The server preflight refreshed this account's cache. Read that
        // authoritative state; the exception itself must never grant access.
        await _load();
        if (!mounted || !_sameOwner(expectedOwner)) return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } catch (_) {
      if (mounted && (owner == null || _sameOwner(owner))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("구매가 완료되지 않았어요. 잠시 후 다시 확인해 주세요."))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
        if (!_sameOwner(owner ?? initialOwner)) await _load();
      }
    }
  }

  Future<void> _cancel() async {
    if (_purchasing ||
        _refreshingStatus ||
        !SubscriptionService.storeBillingEnabled) {
      return;
    }
    final owner = _billing.currentUid;
    setState(() => _purchasing = true);
    _awaitingManagementReturn = true;
    _managementOwner = owner;
    try {
      await _billing.cancel();
      // Never mark the subscription cancelled just because Play opened.
    } catch (_) {
      _awaitingManagementReturn = false;
      if (mounted && _sameOwner(owner)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                "구독 관리 화면을 열지 못했어요. Play 스토어 → 프로필 → 결제 및 정기 결제 → 정기 결제에서 해지할 수 있어요.",
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
        if (!_sameOwner(owner)) await _load();
      }
    }
  }

  Future<void> _restore() async {
    if (_purchasing || !SubscriptionService.storeBillingEnabled) return;
    ++_loadGeneration;
    setState(() => _purchasing = true);
    final initialOwner = _billing.currentUid;
    String? owner;
    try {
      if (!await _billing.ensureSignedIn(context) || !mounted) return;
      owner = _billing.currentUid;
      if (owner == null) return;
      final result = await _billing.restore();
      if (!mounted || !_sameOwner(owner)) return;
      // An unavailable restore is not proof that an existing entitlement ended.
      // In particular, do not overwrite access refreshed by the account bridge
      // while this attempt was waiting for Play.
      if (result.unavailable) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }
      final active = result.active;
      final plan = await _billing.currentPlan();
      if (!mounted || !_sameOwner(owner)) return;
      var statusLabel = active ? tr("마음냥 구독 이용 중") : tr("무료 이용 중");
      try {
        statusLabel = await _billing.statusLabel();
      } catch (_) {}
      if (!mounted || !_sameOwner(owner)) return;
      setState(() {
        _isPremium = active;
        _displayOwner = owner;
        _activePlan = plan;
        _statusLabel = statusLabel;
      });
      _applyPremium(active);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (mounted && (owner == null || _sameOwner(owner))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              const SubscriptionRestoreResult(
                SubscriptionRestoreStatus.unavailable,
              ).message,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
        if (!_sameOwner(owner ?? initialOwner)) await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (FeatureFlags.debugUnlockAllPremium) return const MembershipTestScreen();
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
                          tr("마음냥 구독"),
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
                                  monthlyPrice: _billing.priceLabelFor(
                                    SubscriptionPlan.monthly,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextButton(
                                  onPressed: _purchasing
                                      ? null
                                      : () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AccountScreen(),
                                            ),
                                          );
                                          if (mounted) await _load();
                                        },
                                  child: Text(tr("간편 로그인 · 구매 계정 관리")),
                                ),
                                if (!_isPremium) ...[
                                  _PlanSelector(
                                    selected: _selectedPlan,
                                    billing: _billing,
                                    onChanged: _purchasing
                                        ? null
                                        : (p) =>
                                              setState(() => _selectedPlan = p),
                                  ),
                                  const SizedBox(height: 18),
                                ],
                                if (!_isPremium)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      _billing.offerLabelFor(_selectedPlan),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(_statusLabel),
                                ),
                                const _FeatureList(),
                                const SizedBox(height: 24),
                                if (_isPremium) ...[
                                  Center(
                                    child: Text(
                                      tr("이미 마음냥 구독 멤버십을 이용 중이에요 🌿"),
                                      textAlign: TextAlign.center,
                                      style: bodyFont(
                                        fontSize: 13,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SecondaryButton(
                                    label: tr("멤버십 해지하기"),
                                    onTap: _purchasing || _refreshingStatus
                                        ? null
                                        : _cancel,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    tr(
                                      "Google Play 화면에서 해지를 완료해 주세요. 해지 후에도 이미 결제한 기간까지 이용할 수 있어요.",
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_activePlan == SubscriptionPlan.monthly &&
                                      _supportedStore) ...[
                                    const SizedBox(height: 10),
                                    OutlinedButton(
                                      onPressed:
                                          _purchasing ||
                                              _refreshingStatus ||
                                              !_billing.hasProduct(
                                                SubscriptionPlan.yearly,
                                              )
                                          ? null
                                          : _changeToYearly,
                                      child: Text(
                                        tr("연간으로 변경 · {0}", [
                                          _billing.priceLabelFor(
                                            SubscriptionPlan.yearly,
                                          ),
                                        ]),
                                      ),
                                    ),
                                    Text(
                                      tr(
                                        "Play 결제 화면에서 남은 이용 기간 반영과 금액을 확인할 수 있어요.",
                                      ),
                                    ),
                                  ],
                                  TextButton(
                                    onPressed: _purchasing || _refreshingStatus
                                        ? null
                                        : _refreshSubscriptionStatus,
                                    child: Text(
                                      _refreshingStatus
                                          ? tr("구독 상태 확인 중…")
                                          : tr("구독 상태 다시 확인"),
                                    ),
                                  ),
                                ] else ...[
                                  _PrimaryPurchaseButton(
                                    loading: _purchasing,
                                    enabled: _billingReady,
                                    disabledLabel: !_supportedStore
                                        ? tr("Android 앱에서 이용")
                                        : _billing.hasProduct(_selectedPlan)
                                        ? tr("결제 연결 준비 중")
                                        : tr("구독 상품 확인 필요"),
                                    onTap: _purchase,
                                  ),
                                  if (_supportedStore &&
                                      SubscriptionService
                                          .storeBillingEnabled) ...[
                                    const SizedBox(height: 10),
                                    _SecondaryButton(
                                      label: tr("구매 복원"),
                                      onTap: _purchasing ? null : _restore,
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      _billingCaption,
                                      textAlign: TextAlign.center,
                                      style: bodyFont(
                                        fontSize: 11,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ),
                                  if (_supportedStore && !_billingReady)
                                    TextButton(
                                      onPressed: _purchasing ? null : _load,
                                      child: Text(tr("구독 상품 다시 확인")),
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
  final SubscriptionPlan? activePlan;
  final String monthlyPrice;
  const _HeroCard({
    required this.isPremium,
    required this.activePlan,
    required this.monthlyPrice,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final activeLabel = switch (activePlan) {
      SubscriptionPlan.yearly => tr("현재 이용 중 ✓ (연간)"),
      SubscriptionPlan.monthly => tr("현재 이용 중 ✓ (월간)"),
      null => tr("현재 이용 중 ✓"),
    };
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      child: Column(
        children: [
          const Text('🌷', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 14),
          Text(
            tr("정원을 더 깊이\n돌아볼 수 있어요"),
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 21, color: AppColors.ink, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            tr(
              "기록과 기본 정원은 무료로 시작해요.\n구독으로 장식과 이야기, 돌아보는 경험을 넓혀보세요.\n오프라인 클래스는 현재 구독 혜택에 포함되지 않아요.",
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
              isPremium ? activeLabel : monthlyPrice,
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
  final ValueChanged<SubscriptionPlan>? onChanged;
  final PremiumScreenBilling billing;
  const _PlanSelector({
    required this.selected,
    required this.onChanged,
    required this.billing,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Row(
      children: [
        Expanded(
          child: _PlanCard(
            plan: SubscriptionPlan.monthly,
            title: tr("월간"),
            price: billing.priceLabelFor(SubscriptionPlan.monthly),
            caption: tr("언제든 부담 없이"),
            selected: selected == SubscriptionPlan.monthly,
            onTap: onChanged == null
                ? null
                : () => onChanged!(SubscriptionPlan.monthly),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PlanCard(
            plan: SubscriptionPlan.yearly,
            title: tr("연간"),
            price: billing.priceLabelFor(SubscriptionPlan.yearly),
            caption: tr("매년 결제"),
            selected: selected == SubscriptionPlan.yearly,
            onTap: onChanged == null
                ? null
                : () => onChanged!(SubscriptionPlan.yearly),
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
  final bool selected;
  final VoidCallback? onTap;
  const _PlanCard({
    required this.plan,
    required this.title,
    required this.price,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
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
            color: selected ? AppColors.blobButterAccent : AppColors.line,
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
                const Spacer(),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 18,
                  color: selected
                      ? AppColors.blobButterAccent
                      : AppColors.inkSoft.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(price, style: numberFont(fontSize: 16, color: AppColors.ink)),
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

  static List<(String, String, String)> get _features => [
    (
      '🌳',
      tr("내 시간이 쌓이는 정원"),
      tr("구독 장식과 공개된 정원 이야기를 이어가요. 이미 받은 장식은 구독이 끝나도 남아요."),
    ),
    (
      '📚',
      tr("나를 돌아보는 월간 기록집"),
      tr(
        "내가 고른 문장·나무의 기억·돌봄 경험을 한 달씩 모아요. 첫 기본 기록집은 무료이고, 기존 기록집은 계속 볼 수 있어요.",
      ),
    ),
    (
      '🌷',
      tr("함께 만드는 기억"),
      tr("이웃을 초대해 기념 나무를 함께 가꿔요. 초대받은 친구는 무료로 참여할 수 있어요."),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          for (final f in [
            if (AdService.instance.configured)
              (
                '🌿',
                tr("광고 없이 이용"),
                tr("구독 기간과 구독 무료체험 기간에는 홈 배너 광고가 표시되지 않아요"),
              ),
            ..._features,
          ])
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
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(tr("그 밖의 구독 혜택")),
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  tr("상세 주간·월간 통계와 지난달·분기 비교, 요일·시간대 기록 패턴, ") +
                      tr("나에게 도움이 됐던 돌봄의 긴 기간 비교, 감정을 돌아보는 질문, ") +
                      tr("오늘의 카드와 내 마음, 돌봄 온기 포인트, 주제별 실천 여정을 이용할 수 있어요. ") +
                      tr("정원의 다음 이야기는 구독과 기록 3일·5일 조건으로 열려요. ") +
                      tr("오프라인 클래스 참가비는 구독에 포함되지 않아요."),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryPurchaseButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback? onTap;
  final String disabledLabel;
  const _PrimaryPurchaseButton({
    required this.loading,
    required this.onTap,
    this.enabled = true,
    this.disabledLabel = '구독 상품 확인 필요',
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
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
                enabled ? tr("마음냥 구독 시작하기") : tr(disabledLabel),
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
  final VoidCallback? onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
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
