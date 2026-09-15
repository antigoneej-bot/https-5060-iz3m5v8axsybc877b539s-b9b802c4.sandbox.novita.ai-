import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:in_app_purchase/in_app_purchase.dart';

/// [PurchaseService]가 사용자에게 안내해야 하는 상황의 종류(언어 중립).
/// 이 서비스는 위젯/BuildContext에 접근할 수 없으므로 실제 문자열이 아니라
/// 이 종류값만 [PurchaseService.onPurchaseMessage] 콜백으로 전달하고, 화면
/// 쪽(BuildContext가 있는 곳)에서 lib/l10n/purchase_l10n.dart의
/// purchaseMessageText()를 통해 [AppLocalizations] 기반 문자열로 바꿔
/// 스낵바 등에 표시한다 (다른 서비스들의 l10n "Kind" 패턴과 동일).
enum PurchaseMessageKind {
  /// 웹 프리뷰에서는 인앱 결제를 테스트할 수 없음.
  webNotSupported,

  /// 웹에서는 구매 복원을 지원하지 않음.
  webRestoreNotSupported,

  /// 결제 서비스 초기화 실패 - 잠시 후 다시 시도해야 함.
  serviceUnavailable,

  /// 스토어에서 상품 정보를 불러오지 못함(등록 상태 문제 등).
  productNotFound,

  /// 구매 요청 자체가 예외로 실패함.
  requestFailed,

  /// [PurchaseDetails.error]에 담긴 스토어 쪽 에러 - [detail]에 원본 메시지가
  /// 있으면 함께 보여줄 수 있지만, 없으면 일반적인 안내문으로 대체한다.
  storeError,
}

/// [PurchaseMessageKind]와 함께 전달되는, 사람이 읽을 수 있는 부가 정보.
/// 현재는 [PurchaseMessageKind.storeError]에서 스토어가 준 원본 에러 메시지를
/// 담아 로그/디버깅에 참고할 수 있게 하는 용도로만 쓰이며, 화면에는 항상
/// 로컬라이즈된 일반 안내문을 우선 표시한다.
class PurchaseMessage {
  final PurchaseMessageKind kind;
  final String? detail;

  const PurchaseMessage(this.kind, {this.detail});
}

/// Play Console(수익 창출 > 인앱 상품)에 반드시 이 문자열과 완전히 동일한 ID로
/// "관리형 상품(비소모성)"을 등록해야 실제 결제가 동작한다.
const String kPremiumFramesProductId = 'premium_frames_pack';

/// 정원 꾸미기 프리미엄 장식 아이템(종이등/무지개 울타리/별빛 조명 등) 팩.
const String kGardenDecorationPackProductId = 'garden_decoration_pack';

/// 시즌 패스("몽이의 마음여정") 프리미엄 트랙 - 이번 시즌 한정으로 구매하면
/// 같은 레벨에서도 훨씬 풍성한 보상(무료 트랙과 나란히 진행)을 받을 수 있다.
/// 시즌이 끝나면 다시 구매해야 하는 소모성 성격이지만, Play Billing에서는
/// 관리형(비소모성) 상품으로 등록하고 시즌마다 [GardenStorage]가 구매 플래그를
/// 리셋해 재구매를 유도한다.
const String kSeasonPassProductId = 'season_pass_premium';

/// "빛의 정수" 충전팩 - 실제 결제(원화)로 소프트 화폐를 직접 채워주는 상품.
/// Play Console에는 반드시 "소모성(consumable)" 상품으로 등록해야 한다.
/// (재구매가 가능해야 하므로 비소모성으로 등록하면 두 번째 구매부터 실패한다.)
const String kLightEssence100ProductId = 'light_essence_100';
const String kLightEssence1000ProductId = 'light_essence_1000';

/// 인앱 구매(Google Play Billing) 연동 서비스.
///
/// - 상품 ID별로 [registerProduct]에 잠금 해제 콜백을 등록해두면, 구매/복원이
///   확인될 때마다 해당 콜백이 자동으로 호출된다 (상품이 늘어나도 이 서비스는
///   수정할 필요가 없는 확장 가능한 구조).
/// - 코어 루프(게임/씨앗/다이어리)는 절대 유료화하지 않는다는 원칙을 지키기 위해,
///   이 서비스가 다루는 대상은 카드 프레임·정원 장식 같은 순수 코스메틱 항목뿐이다.
/// - 웹(kIsWeb)에서는 Play Billing API 자체가 없으므로 모든 메서드가 안전하게 no-op.
/// - ⚠️ 실제 결제창이 뜨려면 Play Console에 상품이 등록되고, 서명된 앱이 최소
///   "내부 테스트" 트랙에 업로드되어 있어야 한다. (자세한 절차는 채팅 안내 참고)
class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  bool get billingConfigured => false; // Enable only after integrated receipt verification.

  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _initialized = false;

  /// 상품 ID -> 구매/복원 확인 시 호출할 잠금 해제 콜백.
  final Map<String, void Function()> _unlockCallbacks = {};

  /// 구매 실패/취소/스토어 미가용 등 사용자에게 안내가 필요한 상황에 호출된다.
  /// 실제 문자열이 아니라 [PurchaseMessage](언어 중립 kind)를 전달하므로,
  /// 호출부(BuildContext가 있는 화면)에서 purchaseMessageText()로 번역해
  /// 표시해야 한다.
  void Function(PurchaseMessage message)? onPurchaseMessage;

  /// 결제가 진행 중(pending)임을 UI에 알리기 위한 콜백.
  void Function()? onPurchasePending;

  /// 특정 상품이 구매/복원되었을 때 실행할 콜백을 등록한다.
  /// GardenProvider.init()에서 앱 시작 시 한 번 등록해두면, 이후 구매 완료 시
  /// [purchaseStream]을 통해 비동기로 이 콜백이 호출되어 로컬 저장소를 갱신한다.
  void registerProduct(String productId, void Function() onUnlocked) {
    _unlockCallbacks[productId] = onUnlocked;
  }

  Future<void> init() async {
    if (kIsWeb || _initialized || !billingConfigured) return;
    try {
      final available = await _iap.isAvailable();
      if (!available) return;
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (Object e) {
          if (kDebugMode) debugPrint('IAP stream error: $e');
        },
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) debugPrint('PurchaseService init failed: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }

  /// [productId] 상품 구매를 시작한다. 결과는 [purchaseStream]을 통해 비동기로
  /// 전달되며, 여기서는 "구매 요청이 정상적으로 접수되었는지"만 반환한다.
  Future<bool> buyProduct(String productId) async {
    if (kIsWeb) {
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.webNotSupported),
      );
      return false;
    }
    await init();
    if (!_initialized) {
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.serviceUnavailable),
      );
      return false;
    }
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.error != null || response.productDetails.isEmpty) {
        onPurchaseMessage?.call(
          const PurchaseMessage(PurchaseMessageKind.productNotFound),
        );
        return false;
      }
      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      if (kDebugMode) debugPrint('buyProduct($productId) failed: $e');
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.requestFailed),
      );
      return false;
    }
  }

  /// [productId] 소모성(consumable) 상품 구매를 시작한다. 빛의 정수 충전팩처럼
  /// 여러 번 반복 구매가 가능해야 하는 상품은 [buyProduct](비소모성)이 아니라
  /// 반드시 이 메서드를 사용해야 하며, Play Console에도 "소모성"으로 등록해야
  /// 두 번째 구매부터 정상 동작한다. 결과는 [buyProduct]와 동일하게
  /// [purchaseStream]을 통해 비동기로 전달된다.
  Future<bool> buyConsumable(String productId) async {
    if (kIsWeb) {
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.webNotSupported),
      );
      return false;
    }
    await init();
    if (!_initialized) {
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.serviceUnavailable),
      );
      return false;
    }
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.error != null || response.productDetails.isEmpty) {
        onPurchaseMessage?.call(
          const PurchaseMessage(PurchaseMessageKind.productNotFound),
        );
        return false;
      }
      final purchaseParam = PurchaseParam(
        productDetails: response.productDetails.first,
      );
      return await _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('buyConsumable($productId) failed: $e');
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.requestFailed),
      );
      return false;
    }
  }

  /// 이전에 구매한 내역을 모두 다시 불러온다(기기 변경/재설치 시 사용).
  /// 등록된 모든 상품에 대해 [purchaseStream]으로 restored 이벤트가 전달된다.
  Future<void> restorePurchases() async {
    if (kIsWeb) {
      onPurchaseMessage?.call(
        const PurchaseMessage(PurchaseMessageKind.webRestoreNotSupported),
      );
      return;
    }
    await init();
    if (!_initialized) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      if (kDebugMode) debugPrint('restorePurchases failed: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final unlock = _unlockCallbacks[purchase.productID];
      if (unlock == null) continue; // 등록되지 않은(모르는) 상품 ID는 무시.
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onPurchasePending?.call();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          unlock();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.error:
          onPurchaseMessage?.call(
            PurchaseMessage(
              PurchaseMessageKind.storeError,
              detail: purchase.error?.message,
            ),
          );
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
        case PurchaseStatus.canceled:
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }
}
