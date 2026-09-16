import 'cloud_service.dart';
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

class SubscriptionService {
  SubscriptionService._();
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

  static const String displayPrice = '월 4,900원';
  static const String displayYearlyPrice = '연 33,000원';
  static const String displayYearlyMonthlyEquivalent = '월 2,750원 상당';
  static const String yearlyDiscountLabel = '44% 할인';
  static const String displayYearlyOriginalPrice = '58,800원';
  static const String yearlySavingsLabel = '25,800원 절약';
  static const String earlybirdLabel = '정원 플러스 멤버십';
  static const String earlybirdCaption = '구독은 언제든 해지할 수 있어요';
  static const String billingComingSoonLabel = '곧 스토어에서 만나요';
  static const String billingComingSoonCaption =
      '결제와 서버 확인 준비 중이에요 · 혜택은 미리 둘러볼 수 있어요';

  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Map<String, ProductDetails> _products = {};
  Completer<bool>? _purchaseCompleter;
  bool _initialized = false;

  /// restorePurchases 동안 활성 구독을 한 건이라도 봤는지.
  /// 오류 없는 Android 조회가 비어 있을 때만 로컬 프리미엄을 끕니다.
  bool _sawActiveEntitlement = false;
  bool restoreUnavailable = false;
  Future<bool>? _restoreInFlight;

  bool hasProduct(SubscriptionPlan plan) =>
      _products.containsKey(productIdFor(plan));

  Future<void> refreshProducts() async {
    if (kIsWeb) return;
    try {
      await init();
      await _queryProducts();
    } catch (e) {
      if (kDebugMode) debugPrint('SubscriptionService products unavailable: $e');
    }
  }

  String productIdFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.yearly ? yearlyProductId : monthlyProductId;

  String priceLabelFor(SubscriptionPlan plan) {
    final id = productIdFor(plan);
    final store = _products[id];
    if (store != null && store.price.isNotEmpty) {
      return '${plan == SubscriptionPlan.yearly ? '연' : '월'} ${store.price}';
    }
    return '가격 확인 중';
  }

  /// 앱 시작 시 한 번 호출: 스토어 연결 + 미완료 구매 처리 + 상품 조회.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    if (!storeBillingEnabled) {
      await _clearLocalPremiumFlag();
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
    for (final p in resp.productDetails) {
      _products[p.id] = p;
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
    _purchaseUpdates = _purchaseUpdates.catchError((Object _) {}).then((_) => _processPurchaseUpdates(purchases));
  }
  Future<void> _processPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != monthlyProductId &&
          purchase.productID != yearlyProductId) continue;
      try {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = CloudService.enabled
              ? (await CloudService.verify(purchase.verificationData.serverVerificationData))['active'] == true
              : _isActiveSubscription(purchase);
          if (ok) {
            _sawActiveEntitlement = true;
            final plan = purchase.productID == yearlyProductId
                ? SubscriptionPlan.yearly
                : SubscriptionPlan.monthly;
            await setPremium(true);
            await setPlan(plan);
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _completePurchaseWait(ok);
          break;
        case PurchaseStatus.error:
          if (kDebugMode) {
            debugPrint('SubscriptionService error: ${purchase.error}');
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _completePurchaseWait(false);
          break;
        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _completePurchaseWait(false);
          break;
      }
      } catch (_) {
        // Leave incomplete purchases pending for a later verified retry.
        _completePurchaseWait(false);
      }
    }
  }

  bool _isActiveSubscription(PurchaseDetails purchase) {
    if (purchase.productID != monthlyProductId &&
        purchase.productID != yearlyProductId) {
      return false;
    }
    // Android: 만료·해지된 구독은 복원/구매 스트림에 안 오거나 미지급 상태.
    // purchased/restored면 활성으로 간주. (서버 검증은 B-1 범위 밖)
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  void _completePurchaseWait(bool ok) {
    final c = _purchaseCompleter;
    if (c != null && !c.isCompleted) c.complete(ok);
  }

  Future<bool> isPremium() async {
    if (CloudService.enabled) return CloudService.cachedPremium();
    if (!storeBillingEnabled) {
      await _clearLocalPremiumFlag();
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  Future<SubscriptionPlan> currentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_planKey);
    return v == 'yearly' ? SubscriptionPlan.yearly : SubscriptionPlan.monthly;
  }

  Future<void> setPlan(SubscriptionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _planKey,
      plan == SubscriptionPlan.yearly ? 'yearly' : 'monthly',
    );
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
        await prefs.setString(_premiumSinceKey, DateTime.now().toIso8601String());
      }
    } else {
      await prefs.remove(_premiumSinceKey);
    }
  }

  /// Play 결제 시트 호출. 성공 시 프리미엄 반영.
  Future<bool> purchasePremium({
    SubscriptionPlan plan = SubscriptionPlan.monthly,
  }) async {
    if (kIsWeb) throw StateError('웹 프리뷰에서는 결제를 지원하지 않아요.');
    if (!CloudService.enabled) throw StateError('서버 결제 확인 준비 후 구매할 수 있어요.');
    if (!storeBillingEnabled) {
      if (kDebugMode) {
        debugPrint(
          'SubscriptionService: 스토어 결제 미연동 — purchasePremium 차단',
        );
      }
      return false;
    }

    if (_purchaseCompleter != null) return false;
    await init();
    if (_products.isEmpty) await _queryProducts();
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

    final accountId = CloudService.enabled ? await CloudService.accountId() : null;
    if (_purchaseCompleter != null) return false;
    _purchaseCompleter = Completer<bool>();
    late final PurchaseParam purchaseParam;
    if (defaultTargetPlatform == TargetPlatform.android &&
        product is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
        applicationUserName: accountId,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product, applicationUserName: accountId);
    }

    try {
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) return false;
      return await _purchaseCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => false,
      );
    } finally {
      _purchaseCompleter = null;
    }
  }

  /// 실제 해지는 Play 구독 관리 페이지로 안내.
  /// 로컬 플래그는 앱 재실행/`restorePurchases` 때 스토어 상태로 다시 맞춥니다.
  Future<void> cancelPremium() async {
    final plan = await currentPlan();
    final sku = productIdFor(plan);
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?sku=$sku&package=com.mysticcat.journal',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 스토어에서 과거 구매를 다시 읽어 프리미엄 동기화.
  /// 활성 구독이 없으면 로컬 프리미엄 플래그를 끕니다(만료·해지 반영).
  Future<bool> restorePurchases() {
    return _restoreInFlight ??= _restoreSafely().whenComplete(() {
      _restoreInFlight = null;
    });
  }

  Future<bool> _restoreSafely() async {
    if (kIsWeb) {
      restoreUnavailable = true;
      return false;
    }
    restoreUnavailable = false;
    if (!storeBillingEnabled) {
      await _clearLocalPremiumFlag();
      return false;
    }
    _sawActiveEntitlement = false;
    try {
      if (!await _iap.isAvailable()) {
        restoreUnavailable = true;
        return isPremium();
      }
      if (defaultTargetPlatform != TargetPlatform.android) {
        // This release targets Android. A restore stream has no reliable
        // empty-result completion signal here; never revoke on a timer.
        await _iap.restorePurchases();
        restoreUnavailable = true;
        return isPremium();
      }
      final addition = _iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases();
      if (response.error != null) {
        restoreUnavailable = true;
        return isPremium();
      }
      if (CloudService.enabled) {
        for (final purchase in response.pastPurchases.where(_isActiveSubscription)) {
          try {
            await CloudService.verify(purchase.verificationData.serverVerificationData);
          } on CloudException catch (error) {
            if (error.code == 'purchase-owner-mismatch' || error.code == 'purchase-migration-required') continue;
            rethrow;
          }
          if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
        }
        final result = await CloudService.refreshEntitlement();
        if (result['active'] == true) {
          await setPlan(result['productId'] == yearlyProductId ? SubscriptionPlan.yearly : SubscriptionPlan.monthly);
        }
        return result['active'] == true;
      }
      final active = response.pastPurchases
          .where(_isActiveSubscription).toList();
      if (active.isEmpty) {
        // A purchase update received during the query takes precedence.
        if (!_sawActiveEntitlement && _purchaseCompleter == null) {
          await _clearLocalPremiumFlag();
        }
        return isPremium();
      }
      final purchase = active.firstWhere(
        (p) => p.productID == yearlyProductId,
        orElse: () => active.first,
      );
      await setPremium(true);
      await setPlan(purchase.productID == yearlyProductId
          ? SubscriptionPlan.yearly : SubscriptionPlan.monthly);
      for (final item in active) {
        if (item.pendingCompletePurchase) {
          await _iap.completePurchase(item);
        }
      }
      return true;
    } catch (e) {
      restoreUnavailable = true;
      if (kDebugMode) debugPrint('SubscriptionService restore: $e');
      // Transport/billing errors do not prove that an entitlement expired.
      return isPremium();
    }
  }

  Future<void> dispose() async {
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
