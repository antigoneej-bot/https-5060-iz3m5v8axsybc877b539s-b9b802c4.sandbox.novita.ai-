import 'gen/app_localizations.dart';
import '../models/light_essence_pack.dart';

/// [LightEssencePack.label]은 결제 로직/Provider에서 공유되는 고정 id 기준
/// 데이터라 한국어로 하드코딩돼 있다. 화면에 보여줄 다국어 이름은 이 헬퍼가
/// productId를 기준으로 번역해서 돌려준다.
String lightEssencePackLabel(AppLocalizations l10n, LightEssencePack pack) {
  switch (pack.productId) {
    case 'light_essence_100':
      return l10n.lightEssencePackLabelSmall;
    case 'light_essence_1000':
      return l10n.lightEssencePackLabelLarge;
    default:
      return pack.label;
  }
}
