import 'access_policy.dart';
import 'cloud_service.dart';
import '../utils/feature_flags.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show PricingPhaseWrapper, RecurrenceMode, ReplacementMode;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// '정원 플러스' 구독(프리미엄) 상태를 관리하는 서비스.
///
/// Google Play 인앱결제(`in_app_purchase`) 연동.
/// 상품 ID는 Play Console 구독과 반드시 일치해야 합니다.
enum SubscriptionPlan { monthly, yearly }

enum SubscriptionRestoreStatus {
  restored,
  noActivePurchase,
  unavailable,
  signInRequired,
}

/// A snapshot of one restore attempt. UI must not infer success from a cached
/// premium flag or read a mutable error flag after another restore has started.
class SubscriptionRestoreResult {
  const SubscriptionRestoreResult(this.status, {this.active = false});

  final SubscriptionRestoreStatus status;
  final bool active;

  bool get unavailable =>
      status == SubscriptionRestoreStatus.unavailable ||
      status == SubscriptionRestoreStatus.signInRequired;

  String get message => switch (status) {
    SubscriptionRestoreStatus.restored => '구독을 복원했어요. 이용 권한을 다시 확인했어요.',
    SubscriptionRestoreStatus.noActivePurchase =>
      '이 계정에서 복원할 구독을 찾지 못했어요. 구매할 때 사용한 마음냥 계정과 Play 계정을 확인해 주세요.',
    SubscriptionRestoreStatus.unavailable =>
      '구매 내역을 확인하지 못했어요. 기존 이용 상태를 유지했으니 연결 후 다시 시도해 주세요.',
    SubscriptionRestoreStatus.signInRequired =>
      '구매할 때 사용한 마음냥 계정으로 로그인한 뒤 다시 시도해 주세요.',
  };
}

class SubscriptionService {
  SubscriptionService._();

  /// Isolated service with real store-stream handling and replaceable server
  /// boundaries. Production callers always use the singleton factory below.
  @visibleForTesting
  SubscriptionService.forTesting({
    required String? Function() currentUid,
    required Future<String> Function(String uid) accountId,
    required Future<Map<String, dynamic>> Function(String token, String uid)
    verifyReceipt,
    required Future<String?> Function(String uid) subscriptionProductId,
    required Future<Map<String, dynamic>> Function(String uid)
    refreshEntitlement,
    Duration purchaseTimeout = const Duration(minutes: 5),
    Future<bool> Function(Uri)? openManagementUrl,
    Future<List<GooglePlayPurchaseDetails>> Function()? pastPurchases,
  }) : _currentUidOverride = currentUid,
       _accountIdOverride = accountId,
       _verifyReceiptOverride = verifyReceipt,
       _subscriptionProductIdOverride = subscriptionProductId,
       _refreshEntitlementOverride = refreshEntitlement,
       _purchaseTimeout = purchaseTimeout,
       _openManagementUrlOverride = openManagementUrl,
       _pastPurchasesOverride = pastPurchases;
  Future<List<GooglePlayPurchaseDetails>> Function()? _pastPurchasesOverride;
  Future<bool> Function(Uri)? _openManagementUrlOverride;
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;

  /// Play 구독 상품·내부테스트 AAB가 준비되면 true.
  /// 콘솔 상품 생성 전이면 false로 두세요.
  static const bool storeBillingEnabled = true;

  /// Play Console 구독 상품 ID (합의안).
  static const String monthlyProductId = 'garden_plus_monthly';
  static const String yearlyProductId = 'garden_plus_yearly';

  static const String _premiumKey = 'is_premium_subscriber';
  static const String _premiumSinceKey = 'premium_since';
  static const String _planKey = 'premium_plan_type';

  /// 관리자 계정(구독 없이 전체 이용). Firebase Auth 로그인 이메일이 여기
  /// 포함되면 [isPremium]이 항상 true를 반환합니다.
  static const Set<String> adminEmails = {'antigone.ej@gmail.com'};

  /// Firebase가 아직 초기화되지 않았거나(예: 시작 직후, 오프라인) 접근에
  /// 실패하는 경우에도 절대 예외를 밖으로 던지지 않습니다. 이 값은 매우
  /// 자주(앱 부트스트랩, 편지 저장 등 거의 모든 진입점에서) 호출되므로,
  /// 여기서 예외가 새어나가면 관리자와 무관한 일반 사용자의 편지 저장까지
  /// 함께 실패하게 됩니다.
  ///
  /// public으로 노출해, [isPremium] 경로를 타지 않는 다른 "전체 공개"
  /// 판단(예: 디버그/운영 확인용 화면 노출)에서도 재사용할 수 있게 합니다.
  static bool get isAdminUser {
    try {
      final user = CloudService.currentUser;
      final email = user?.email?.toLowerCase();
      return user?.emailVerified == true &&
          email != null &&
          adminEmails.contains(email);
    } catch (_) {
      return false;
    }
  }

  static const String displayPrice = '월 4,900원';
  static const String displayYearlyPrice = '연 29,000원';
  static const String displayYearlyMonthlyEquivalent = '월 2,417원 상당';
  static const String yearlyDiscountLabel = '약 51% 할인';
  static const String displayYearlyOriginalPrice = '58,800원';
  static const String yearlySavingsLabel = '29,800원 절약';
  static const String earlybirdLabel = '마음냥 통합 구독';
  static const String earlybirdCaption = '구독은 언제든 해지할 수 있어요';
  static const String billingComingSoonLabel = '곧 스토어에서 만나요';
  static const String billingComingSoonCaption =
      '결제와 서버 확인 준비 중이에요 · 혜택은 미리 둘러볼 수 있어요';

  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Map<String, ProductDetails> _products = {};
  final Map<String, String> _productIssues = {};
  _SubscriptionPurchaseAttempt? _purchaseAttempt;
  final Set<String> _observedReceiptTokens = {};
  String? Function()? _currentUidOverride;
  Future<String> Function(String uid)? _accountIdOverride;
  Future<Map<String, dynamic>> Function(String token, String uid)?
  _verifyReceiptOverride;
  Future<String?> Function(String uid)? _subscriptionProductIdOverride;
  Future<Map<String, dynamic>> Function(String uid)?
  _refreshEntitlementOverride;
  Duration _purchaseTimeout = const Duration(minutes: 5);

  String? get _currentUid {
    final readOwner = _currentUidOverride;
    return readOwner == null ? CloudService.currentUser?.uid : readOwner();
  }

  bool get _cloudEnabled =>
      _verifyReceiptOverride != null || CloudService.enabled;
  Future<String> _accountId(String uid) =>
      _accountIdOverride?.call(uid) ?? CloudService.accountId(expectedUid: uid);
  Future<Map<String, dynamic>> _verifyReceipt(String token, String uid) =>
      _verifyReceiptOverride?.call(token, uid) ??
      CloudService.verify(token, expectedUid: uid);
  Future<String?> _subscriptionProductId(String uid) =>
      _subscriptionProductIdOverride?.call(uid) ??
      CloudService.cachedSubscriptionProductId(expectedUid: uid);
  Future<Map<String, dynamic>> _refreshEntitlement(String uid) =>
      _refreshEntitlementOverride?.call(uid) ??
      CloudService.refreshEntitlement(expectedUid: uid);

  void _requireOwner(String uid) {
    if (_currentUid != uid) throw const CloudException('account-changed');
  }

  bool _initialized = false;
  Future<void>? _initialization;

  /// Compatibility flag for callers that have not adopted the result snapshot.
  bool restoreUnavailable = false;
  Future<bool>? _restoreInFlight;
  Future<SubscriptionRestoreResult>? _restoreResultInFlight;

  bool hasProduct(SubscriptionPlan plan) =>
      _products.containsKey(productIdFor(plan));

  Future<void> refreshProducts() async {
    if (kIsWeb) return;
    try {
      await init();
      await _queryProducts();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SubscriptionService products unavailable: $e');
      }
    }
  }

  String productIdFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.yearly ? yearlyProductId : monthlyProductId;

  List<PricingPhaseWrapper> _phases(ProductDetails? product) {
    if (product is! GooglePlayProductDetails) return const [];
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null ||
        offers == null ||
        index < 0 ||
        index >= offers.length) {
      return const [];
    }
    return offers[index].pricingPhases;
  }

  List<StorePhase> _policyPhases(ProductDetails? product) => _phases(product)
      .map(
        (p) => StorePhase(
          p.billingPeriod,
          p.priceCurrencyCode,
          p.priceAmountMicros,
          p.billingCycleCount,
          recurrence: switch (p.recurrenceMode) {
            RecurrenceMode.infiniteRecurring => StoreRecurrence.infinite,
            RecurrenceMode.finiteRecurring => StoreRecurrence.finite,
            RecurrenceMode.nonRecurring => StoreRecurrence.none,
          },
        ),
      )
      .toList();

  bool _trial(ProductDetails? product) =>
      SubscriptionOfferPolicy.hasTrial(_policyPhases(product));
  bool hasTrialFor(SubscriptionPlan plan) =>
      _trial(_products[productIdFor(plan)]);
  bool _matchesPolicy(ProductDetails product) =>
      SubscriptionOfferPolicy.accepts(
        _policyPhases(product),
        yearly: product.id == yearlyProductId,
      );

  String priceLabelFor(SubscriptionPlan plan) {
    final store = _products[productIdFor(plan)];
    final phases = _phases(store);
    if (phases.isNotEmpty) {
      return '${plan == SubscriptionPlan.yearly ? '연' : '월'} ${phases.last.formattedPrice}';
    }
    return '${plan == SubscriptionPlan.yearly ? '연간' : '월간'} 가격 확인 중';
  }

  String productAvailabilityLabel(SubscriptionPlan plan) =>
      _productIssues[productIdFor(plan)] ??
      '${plan == SubscriptionPlan.yearly ? '연간' : '월간'} 상품을 아직 불러오지 못했어요. 다시 확인해 주세요.';

  String offerLabelFor(SubscriptionPlan plan) {
    final phases = _phases(_products[productIdFor(plan)]);
    if (phases.isEmpty) return productAvailabilityLabel(plan);
    final introductory = phases
        .take(phases.length - 1)
        .map((phase) {
          final match = RegExp(
            r'^P([0-9]+)([DWMY])$',
          ).firstMatch(phase.billingPeriod)!;
          final amount = int.parse(match[1]!);
          final unit = {'D': '일', 'W': '주', 'M': '개월', 'Y': '년'}[match[2]]!;
          if (phase.priceAmountMicros == 0) {
            return '${amount * phase.billingCycleCount}$unit 무료체험';
          }
          return '$amount$unit마다 ${phase.formattedPrice} · ${phase.billingCycleCount}회';
        })
        .join(' → ');
    return '${introductory.isEmpty ? '' : '$introductory 후 '}${priceLabelFor(plan)} 자동 결제 · 결제 전 Google Play의 최종 조건을 확인해 주세요.';
  }

  /// 앱 시작 시 한 번 호출: 스토어 연결 + 미완료 구매 처리 + 상품 조회.
  Future<void> init() {
    final pending = _initialization;
    if (pending != null) return pending;
    if (_initialized) return Future<void>.value();
    // Startup, the paywall and a purchase can all ask to initialize. They must
    // await the same store connection instead of observing an early ready flag.
    late final Future<void> initialization;
    initialization = _initialize().whenComplete(() {
      if (identical(_initialization, initialization)) _initialization = null;
    });
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    if (!storeBillingEnabled) {
      await _clearLocalPremiumFlag();
      _initialized = true;
      return;
    }

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        _initialized = false;
        if (kDebugMode) debugPrint('SubscriptionService: 스토어 사용 불가');
        return;
      }

      _purchaseSub ??= _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object e) {
          if (kDebugMode) debugPrint('SubscriptionService purchaseStream: $e');
        },
      );

      await _queryProducts();
      await restorePurchases();
      _initialized = true;
    } catch (e) {
      _initialized = false;
      if (kDebugMode) debugPrint('SubscriptionService init: $e');
    }
  }

  Future<void> _queryProducts() async {
    final ids = <String>{monthlyProductId, yearlyProductId};
    final resp = await _iap.queryProductDetails(ids);
    if (resp.error != null && kDebugMode) {
      debugPrint('SubscriptionService query error: ${resp.error}');
    }
    _products.clear();
    _productIssues.clear();
    for (final id in ids) {
      final name = id == yearlyProductId ? '연간' : '월간';
      _productIssues[id] = resp.error != null
          ? 'Google Play에서 $name 상품을 확인하지 못했어요. 잠시 후 다시 확인해 주세요.'
          : '$name 구독 상품이 이 Play 계정에서 조회되지 않아요. 다른 상품은 별도로 이용할 수 있어요.';
    }
    for (final p in resp.productDetails) {
      if (!ids.contains(p.id)) continue;
      if (!_matchesPolicy(p)) {
        if (!_products.containsKey(p.id)) {
          _productIssues[p.id] =
              '이 상품의 결제 주기를 확인하지 못했어요. 월간·연간 자동 갱신 상품 설정을 확인해 주세요.';
        }
        continue;
      }
      final previous = _products[p.id];
      // Prefer the lower recurring price; a free trial must not select a more
      // expensive recurring plan. All displayed terms come from this offer.
      final price = _phases(p).last.priceAmountMicros;
      final previousPrice = previous == null
          ? null
          : _phases(previous).last.priceAmountMicros;
      if (previousPrice == null ||
          price < previousPrice ||
          (price == previousPrice && _trial(p) && !_trial(previous))) {
        _products[p.id] = p;
      }
      _productIssues.remove(p.id);
    }
    if (kDebugMode) {
      debugPrint(
        'SubscriptionService products: ${_products.keys.toList()} '
        'notFound=${resp.notFoundIDs}',
      );
    }
  }

  Future<void> _purchaseUpdates = Future.value();
  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    // Capture the attempt and owner when the store emits the event, before
    // queued verification awaits. An old queued event cannot finish a new buy.
    final attempt = _purchaseAttempt;
    final owner = _currentUid;
    for (final purchase in purchases) {
      final token = purchase.verificationData.serverVerificationData;
      if (token.isNotEmpty) _observedReceiptTokens.add(token);
    }
    _purchaseUpdates = _purchaseUpdates
        .catchError((Object _) {})
        .then((_) => _processPurchaseUpdates(purchases, attempt, owner));
  }

  Future<void> _processPurchaseUpdates(
    List<PurchaseDetails> purchases,
    _SubscriptionPurchaseAttempt? attempt,
    String? owner,
  ) async {
    for (final purchase in purchases) {
      final matchesAttempt =
          attempt != null &&
          owner == attempt.owner &&
          attempt.matches(purchase);
      if (purchase.productID != monthlyProductId &&
          purchase.productID != yearlyProductId) {
        // Play cancellation/errors may carry no product or transaction data.
        // They may end only the flow that was present when this event arrived;
        // they never verify a receipt or grant access.
        if (purchase.productID.isEmpty &&
            attempt != null &&
            owner == attempt.owner &&
            (purchase.status == PurchaseStatus.canceled ||
                purchase.status == PurchaseStatus.error)) {
          _completePurchaseWait(attempt, false);
        }
        continue;
      }
      try {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            break;
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            if (!_cloudEnabled || owner == null) {
              if (matchesAttempt) _completePurchaseWait(attempt, false);
              break;
            }
            _requireOwner(owner);
            final result = await _verifyReceipt(
              purchase.verificationData.serverVerificationData,
              owner,
            );
            _requireOwner(owner);
            final ok = result['active'] == true;
            if (ok) {
              await setPremium(true);
              _requireOwner(owner);
              // A paid receipt is acknowledged only after the server has
              // actually granted entitlement. An inactive/failed response is
              // left available for verified restoration instead of swallowed.
              if (purchase.pendingCompletePurchase) {
                await _iap.completePurchase(purchase);
                _requireOwner(owner);
              }
            }
            if (matchesAttempt)
              _completePurchaseWait(
                attempt,
                ok &&
                    (!attempt.requireProductMatch ||
                        result['productId'] == attempt.productId),
              );
            break;
          case PurchaseStatus.error:
            if (kDebugMode) {
              debugPrint('SubscriptionService error: ${purchase.error}');
            }
            if (matchesAttempt) _completePurchaseWait(attempt, false);
            break;
          case PurchaseStatus.canceled:
            if (matchesAttempt) _completePurchaseWait(attempt, false);
            break;
        }
      } catch (_) {
        // Leave incomplete purchases pending for a later verified retry.
        if (matchesAttempt) _completePurchaseWait(attempt, false);
      }
    }
  }

  bool _isActiveSubscription(PurchaseDetails purchase) {
    if (purchase.productID != monthlyProductId &&
        purchase.productID != yearlyProductId) {
      return false;
    }
    // These statuses are candidates only; the server decides entitlement.
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  void _completePurchaseWait(_SubscriptionPurchaseAttempt? attempt, bool ok) {
    if (attempt == null || !identical(_purchaseAttempt, attempt)) return;
    if (!attempt.result.isCompleted) {
      attempt.result.complete(ok && _currentUid == attempt.owner);
    }
  }

  /// Test-only override so widget/unit tests can simulate an active
  /// subscription without a real server or store connection. Must stay
  /// null in production; only ever set from test setUp/tearDown.
  @visibleForTesting
  static bool? debugIsPremiumOverride;

  Future<bool> isPremium() async {
    if (isAdminUser) return true;
    final override = debugIsPremiumOverride;
    // 단위 테스트가 명시적으로 설정한 override가 항상 최우선입니다(무료
    // 쿼터 등 특정 상태를 검증하는 테스트를 방해하지 않기 위함).
    if (kDebugMode && override != null) return override;
    // ⚠️ 테스트 전용 스위치. FeatureFlags.debugUnlockAllPremium 을 참고.
    // kDebugMode 가드 없이 release 빌드에도 적용되도록 임시로 열어둔
    // 상태입니다(결제 QA 목적). 정식 배포(스토어 출시) 전 반드시
    // FeatureFlags.debugUnlockAllPremium = false 로 되돌려야 합니다.
    if (FeatureFlags.debugUnlockAllPremium) return true;
    if (CloudService.enabled) return CloudService.cachedPremium();
    if (!storeBillingEnabled) {
      await _clearLocalPremiumFlag();
      return false;
    }
    // Never grant access from an editable legacy preference alone.
    return false;
  }

  Future<SubscriptionPlan> currentPlan() async {
    // Kept non-null for older callers. UI that describes an existing purchase
    // should use currentPlanIfKnown instead of treating this default as proof.
    return await currentPlanIfKnown() ?? SubscriptionPlan.monthly;
  }

  Future<SubscriptionPlan?> currentPlanIfKnown() async {
    final uid = _currentUid;
    if (uid == null) return null;
    final productId = await _subscriptionProductId(uid);
    _requireOwner(uid);
    return switch (productId) {
      monthlyProductId => SubscriptionPlan.monthly,
      yearlyProductId => SubscriptionPlan.yearly,
      _ => null,
    };
  }

  Future<void> setPlan(SubscriptionPlan plan) async {
    // Compatibility cleanup: plan authority now belongs to the verified
    // current-account entitlement, never a device-wide preference.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
  }

  Future<DateTime?> premiumSince() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_premiumSinceKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> setPremium(bool v) async {
    if (v && !storeBillingEnabled) {
      if (kDebugMode) {
        debugPrint(
          'SubscriptionService: storeBillingEnabled=false — setPremium(true) 무시',
        );
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, v);
    if (v) {
      if (!prefs.containsKey(_premiumSinceKey)) {
        await prefs.setString(
          _premiumSinceKey,
          DateTime.now().toIso8601String(),
        );
      }
    } else {
      await prefs.remove(_premiumSinceKey);
    }
  }

  /// Play 결제 시트 호출. 성공 시 프리미엄 반영.
  Future<bool> purchasePremium({
    SubscriptionPlan plan = SubscriptionPlan.monthly,
    bool replaceMonthly = false,
  }) async {
    if (kIsWeb) throw StateError('웹 프리뷰에서는 결제를 지원하지 않아요.');
    if (!_cloudEnabled) throw StateError('서버 결제 확인 준비 후 구매할 수 있어요.');
    if (!storeBillingEnabled) {
      if (kDebugMode) {
        debugPrint('SubscriptionService: 스토어 결제 미연동 — purchasePremium 차단');
      }
      return false;
    }

    if (_purchaseAttempt != null) return false;
    final owner = _currentUid;
    if (owner == null) throw const CloudException('authentication-required');
    await init();
    _requireOwner(owner);
    if (!_products.containsKey(productIdFor(plan))) await _queryProducts();
    _requireOwner(owner);
    final product = _products[productIdFor(plan)];
    if (product == null) {
      if (kDebugMode) {
        debugPrint(
          'SubscriptionService: 상품 없음 ${productIdFor(plan)} — '
          'Play Console 구독·내부테스트 AAB를 확인하세요',
        );
      }
      return false;
    }

    final accountId = await _accountId(owner);
    _requireOwner(owner);
    if (_purchaseAttempt != null) return false;
    // A fresh owner-bound server status prevents a second subscription and
    // supplies a trusted clock. Phone clock skew must never turn a delivered
    // Play purchase into a five-minute wait followed by a false failure.
    final status = await _refreshEntitlement(owner);
    _requireOwner(owner);
    if (_purchaseAttempt != null) return false;
    GooglePlayPurchaseDetails? oldPurchase;
    if (replaceMonthly) {
      if (plan != SubscriptionPlan.yearly ||
          defaultTargetPlatform != TargetPlatform.android ||
          product is! GooglePlayProductDetails ||
          status['active'] != true ||
          status['productId'] != monthlyProductId) {
        throw const CloudException('subscription-check-unavailable');
      }
      final purchases =
          await (_pastPurchasesOverride?.call() ?? _pastAndroidPurchases());
      _requireOwner(owner);
      for (final old in purchases.where(
        (p) => p.productID == monthlyProductId && _isActiveSubscription(p),
      )) {
        final verified = await _verifyReceipt(
          old.verificationData.serverVerificationData,
          owner,
        );
        _requireOwner(owner);
        if (verified['active'] == true &&
            verified['productId'] == monthlyProductId) {
          if (oldPurchase != null)
            throw const CloudException('subscription-check-unavailable');
          oldPurchase = old;
        }
      }
      if (oldPurchase == null)
        throw const CloudException('subscription-check-unavailable');
      _observedReceiptTokens.add(
        oldPurchase.verificationData.serverVerificationData,
      );
    } else if (status['active'] == true) {
      throw const CloudException('subscription-already-active');
    }
    final checkedAt = status['checkedAt'];
    final startedAt = checkedAt is String ? DateTime.tryParse(checkedAt) : null;
    if ((!replaceMonthly && status['active'] != false) ||
        startedAt == null ||
        !startedAt.isUtc) {
      throw const CloudException('subscription-check-unavailable');
    }
    if (_purchaseAttempt != null) return false;
    final attempt = _SubscriptionPurchaseAttempt(
      owner: owner,
      requireProductMatch: replaceMonthly,
      productId: product.id,
      startedAt: startedAt,
      previouslyObservedTokens: Set.of(_observedReceiptTokens),
    );
    _purchaseAttempt = attempt;
    late final PurchaseParam purchaseParam;
    if (defaultTargetPlatform == TargetPlatform.android &&
        product is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
        applicationUserName: accountId,
        changeSubscriptionParam: oldPurchase == null
            ? null
            : ChangeSubscriptionParam(
                oldPurchaseDetails: oldPurchase,
                replacementMode: ReplacementMode.chargeFullPrice,
              ),
      );
    } else {
      purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: accountId,
      );
    }

    try {
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      _requireOwner(owner);
      if (!started) return false;
      final ok = await attempt.result.future.timeout(
        _purchaseTimeout,
        onTimeout: () => false,
      );
      return ok && _currentUid == owner;
    } finally {
      if (identical(_purchaseAttempt, attempt)) _purchaseAttempt = null;
    }
  }

  Future<List<GooglePlayPurchaseDetails>> _pastAndroidPurchases() async {
    final response = await _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
        .queryPastPurchases();
    if (response.error != null)
      throw const CloudException('subscription-check-unavailable');
    return response.pastPurchases;
  }

  /// 실제 해지는 Play 구독 관리 페이지로 안내.
  /// Opening management is not a cancellation. The screen refreshes verified
  /// entitlement after return; paid access lasts through the expiration date.
  Future<void> cancelPremium() async {
    final owner = _currentUid;
    if (owner == null) throw const CloudException('authentication-required');
    final uri = await subscriptionManagementUri();
    if (_currentUid != owner) throw const CloudException('account-changed');
    // canLaunchUrl can be false on Android even when launchUrl works.
    final urls = <Uri>{
      uri,
      Uri.https('play.google.com', '/store/account/subscriptions'),
    };
    for (final target in urls) {
      _requireOwner(owner);
      var opened = false;
      try {
        opened =
            await (_openManagementUrlOverride?.call(target) ??
                launchUrl(target, mode: LaunchMode.externalApplication));
      } catch (_) {
        // Try the subscriptions list if the product-specific link fails.
      }
      _requireOwner(owner);
      if (opened) return;
    }
    throw StateError('subscription-management-unavailable');
  }

  Future<Uri> subscriptionManagementUri() async {
    final plan = await currentPlanIfKnown();
    return Uri.https(
      'play.google.com',
      '/store/account/subscriptions',
      plan == null
          ? null
          : {'package': 'com.mysticcat.journal', 'sku': productIdFor(plan)},
    );
  }

  /// 스토어에서 과거 구매를 다시 읽어 프리미엄 동기화.
  /// 활성 구독이 없으면 로컬 프리미엄 플래그를 끕니다(만료·해지 반영).
  Future<bool> restorePurchases() {
    return _restoreInFlight ??= restorePurchasesWithResult()
        .then((result) => result.active)
        .whenComplete(() {
          _restoreInFlight = null;
        });
  }

  Future<SubscriptionRestoreResult> restorePurchasesWithResult() {
    return _restoreResultInFlight ??= _restoreSafely()
        .then((result) {
          // Retained for existing callers; new UI uses the result snapshot above.
          restoreUnavailable = result.unavailable;
          return result;
        })
        .whenComplete(() {
          _restoreResultInFlight = null;
        });
  }

  Future<SubscriptionRestoreResult> _unavailableRestore() async =>
      SubscriptionRestoreResult(
        SubscriptionRestoreStatus.unavailable,
        active: await isPremium(),
      );

  Future<SubscriptionRestoreResult> _restoreSafely() async {
    if (kIsWeb) {
      return _unavailableRestore();
    }
    if (!storeBillingEnabled) {
      await _clearLocalPremiumFlag();
      return const SubscriptionRestoreResult(
        SubscriptionRestoreStatus.unavailable,
      );
    }
    if (!_cloudEnabled) return _unavailableRestore();
    final restoringUid = _currentUid;
    if (restoringUid == null) {
      return const SubscriptionRestoreResult(
        SubscriptionRestoreStatus.signInRequired,
      );
    }
    try {
      if (!await _iap.isAvailable()) {
        return _unavailableRestore();
      }
      if (defaultTargetPlatform != TargetPlatform.android) {
        // This release targets Android. A restore stream has no reliable
        // empty-result completion signal here; never revoke on a timer.
        await _iap.restorePurchases();
        return _unavailableRestore();
      }
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        return _unavailableRestore();
      }
      if (_cloudEnabled) {
        for (final purchase in response.pastPurchases.where(
          _isActiveSubscription,
        )) {
          if (_currentUid != restoringUid) {
            return const SubscriptionRestoreResult(
              SubscriptionRestoreStatus.signInRequired,
            );
          }
          final token = purchase.verificationData.serverVerificationData;
          if (token.isNotEmpty) _observedReceiptTokens.add(token);
          var active = false;
          try {
            final result = await _verifyReceipt(token, restoringUid);
            _requireOwner(restoringUid);
            active = result['active'] == true;
          } on CloudException catch (error) {
            if (error.code == 'purchase-owner-mismatch' ||
                error.code == 'purchase-migration-required') {
              continue;
            }
            rethrow;
          }
          if (active && purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
            _requireOwner(restoringUid);
          }
        }
        if (_currentUid != restoringUid) {
          return const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.signInRequired,
          );
        }
        final result = await _refreshEntitlement(restoringUid);
        if (_currentUid != restoringUid) {
          return const SubscriptionRestoreResult(
            SubscriptionRestoreStatus.signInRequired,
          );
        }
        final active = result['active'] == true;
        return SubscriptionRestoreResult(
          active
              ? SubscriptionRestoreStatus.restored
              : SubscriptionRestoreStatus.noActivePurchase,
          active: active,
        );
      }
      return _unavailableRestore();
    } catch (e) {
      if (kDebugMode) debugPrint('SubscriptionService restore: $e');
      if (e is CloudException &&
          {
            'authentication-required',
            'account-changed',
            'verify-email',
          }.contains(e.code)) {
        return const SubscriptionRestoreResult(
          SubscriptionRestoreStatus.signInRequired,
        );
      }
      // Transport/billing errors do not prove that an entitlement expired.
      return _unavailableRestore();
    }
  }

  Future<void> dispose() async {
    _completePurchaseWait(_purchaseAttempt, false);
    _purchaseAttempt = null;
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    _initialized = false;
  }

  Future<void> _clearLocalPremiumFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_premiumKey) == true) {
      await prefs.setBool(_premiumKey, false);
      await prefs.remove(_premiumSinceKey);
      if (kDebugMode) {
        debugPrint('SubscriptionService: 로컬 프리미엄 플래그 제거');
      }
    }
  }
}

class _SubscriptionPurchaseAttempt {
  _SubscriptionPurchaseAttempt({
    required this.owner,
    this.requireProductMatch = false,
    required this.productId,
    required this.startedAt,
    required this.previouslyObservedTokens,
  });

  final String owner;
  final bool requireProductMatch;
  final String productId;
  final DateTime startedAt;
  final Set<String> previouslyObservedTokens;
  final Completer<bool> result = Completer<bool>();

  bool matches(PurchaseDetails purchase) {
    if (purchase.productID != productId ||
        purchase.status == PurchaseStatus.restored) {
      return false;
    }
    final token = purchase.verificationData.serverVerificationData;
    if (token.isNotEmpty && previouslyObservedTokens.contains(token)) {
      return false;
    }
    final transactionMs = int.tryParse(purchase.transactionDate ?? '');
    // Google Play supplies purchaseTime in milliseconds. Permit second-level
    // truncation, but never call an undated/old successful receipt a new buy.
    if (transactionMs != null) {
      return transactionMs >= (startedAt.millisecondsSinceEpoch ~/ 1000) * 1000;
    }
    return purchase.status == PurchaseStatus.canceled ||
        purchase.status == PurchaseStatus.error;
  }
}
