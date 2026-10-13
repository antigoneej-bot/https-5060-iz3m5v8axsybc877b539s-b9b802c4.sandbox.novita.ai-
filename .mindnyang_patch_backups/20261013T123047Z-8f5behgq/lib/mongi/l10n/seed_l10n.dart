import 'gen/app_localizations.dart';
import '../models/seed.dart';

/// [SeedType.label]/[SeedType.description]는 하위 호환을 위해 한글로
/// 고정되어 있다 - 화면에서는 이 헬퍼를 통해 [AppLocalizations] 기반의
/// 다국어 문구로 바꿔서 표시한다.
String seedLabel(AppLocalizations l10n, SeedType seed) {
  switch (seed.id) {
    case 'forgiveness':
      return l10n.gardenSeedNameForgiveness;
    case 'love':
      return l10n.gardenSeedNameLove;
    case 'peace':
      return l10n.gardenSeedNamePeace;
    default:
      return seed.label;
  }
}

/// [SeedType.description]의 다국어 버전.
String seedDescription(AppLocalizations l10n, SeedType seed) {
  switch (seed.id) {
    case 'forgiveness':
      return l10n.gardenSeedDescForgiveness;
    case 'love':
      return l10n.gardenSeedDescLove;
    case 'peace':
      return l10n.gardenSeedDescPeace;
    default:
      return seed.description;
  }
}
