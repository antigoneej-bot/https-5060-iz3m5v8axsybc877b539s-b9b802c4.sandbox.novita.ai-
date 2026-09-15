import '../services/purchase_service.dart';
import 'gen/app_localizations.dart';

/// [PurchaseService.onPurchaseMessage]로 전달되는 언어 중립 [PurchaseMessage]를
/// 화면에 표시할 실제 문자열로 바꿔주는 UI 레이어 헬퍼. 서비스 자체는
/// BuildContext에 접근할 수 없어 항상 [PurchaseMessageKind]만 넘기므로, 실제
/// 스낵바를 띄우는 화면(season_pass_screen.dart, emotion_share_sheet.dart,
/// light_essence_shop_sheet.dart) 쪽에서 이 함수를 통해 번역한다.
///
/// [PurchaseMessageKind.storeError]는 스토어가 준 원본 에러 메시지
/// ([message.detail])가 있어도, 사용자에게는 항상 일관된 로컬라이즈 안내문을
/// 보여준다(스토어 원본 메시지는 보통 영어/기술적인 문구라 그대로 노출하면
/// 오히려 혼란을 줄 수 있기 때문). 원본은 디버깅이 필요하면 별도로 로그에만
/// 남기면 된다.
String purchaseMessageText(AppLocalizations l10n, PurchaseMessage message) {
  switch (message.kind) {
    case PurchaseMessageKind.webNotSupported:
      return l10n.purchaseMessageWebNotSupported;
    case PurchaseMessageKind.webRestoreNotSupported:
      return l10n.purchaseMessageWebRestoreNotSupported;
    case PurchaseMessageKind.serviceUnavailable:
      return PurchaseService.instance.billingConfigured ? l10n.purchaseMessageServiceUnavailable : '통합 앱의 실제 결제는 준비 중이에요. 게임에서 모은 빛의 정수는 사용할 수 있어요.';
    case PurchaseMessageKind.productNotFound:
      return l10n.purchaseMessageProductNotFound;
    case PurchaseMessageKind.requestFailed:
      return l10n.purchaseMessageRequestFailed;
    case PurchaseMessageKind.storeError:
      return l10n.purchaseMessageStoreError;
  }
}
