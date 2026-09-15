import 'gen/app_localizations.dart';
import '../models/mongi_care_item.dart';

/// [MongiCareItem.name]/[MongiCareItem.reactionMessage]는 결제/저장 로직에서
/// 공유되는 고정 id 기준 데이터라 한국어로 하드코딩돼 있다. 화면에 보여줄
/// 다국어 이름/반응 대사는 이 헬퍼가 아이템 id를 기준으로 번역해서 돌려준다.
String mongiCareItemName(AppLocalizations l10n, MongiCareItem item) {
  switch (item.id) {
    case 'tuna_can':
      return l10n.mongiCareItemNameTunaCan;
    case 'kibble':
      return l10n.mongiCareItemNameKibble;
    case 'clean_water':
      return l10n.mongiCareItemNameCleanWater;
    case 'injeolmi':
      return l10n.mongiCareItemNameInjeolmi;
    case 'blanket':
      return l10n.mongiCareItemNameBlanket;
    case 'mongi_house':
      return l10n.mongiCareItemNameMongiHouse;
    default:
      return item.name;
  }
}

String mongiCareItemReactionMessage(AppLocalizations l10n, MongiCareItem item) {
  switch (item.id) {
    case 'tuna_can':
      return l10n.mongiCareItemReactionTunaCan;
    case 'kibble':
      return l10n.mongiCareItemReactionKibble;
    case 'clean_water':
      return l10n.mongiCareItemReactionCleanWater;
    case 'injeolmi':
      return l10n.mongiCareItemReactionInjeolmi;
    case 'blanket':
      return l10n.mongiCareItemReactionBlanket;
    case 'mongi_house':
      return l10n.mongiCareItemReactionMongiHouse;
    default:
      return item.reactionMessage;
  }
}
