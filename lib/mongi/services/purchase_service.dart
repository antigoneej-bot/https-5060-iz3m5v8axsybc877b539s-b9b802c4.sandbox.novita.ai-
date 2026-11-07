import '../../services/subscription_service.dart';

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
  static final instance = PurchaseService._();
  bool get billingConfigured => false;
  void Function(PurchaseMessage)? onPurchaseMessage;
  void Function()? onPurchasePending;
  void registerProduct(String id, void Function() unlock) {}
  Future<void> init() async {}
  Future<bool> buyProduct(String id) async => false;
  Future<bool> buyConsumable(String id) async => false;
  Future<void> restorePurchases() async {
    await SubscriptionService().restorePurchases();
  }
}
