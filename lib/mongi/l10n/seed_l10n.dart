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

String storedSeedMessage(AppLocalizations l10n) => switch (l10n.localeName.split('_').first) {
  'ko' => '이미 심은 식물이에요. 씨앗 1개를 보관함에 모아둘게요.',
  'ja' => 'この植物は植えてあります。種1個を保管します。',
  _ => 'Already planted. One seed will be saved for later.',
};
String savedSeedTitle(AppLocalizations l10n) => switch (l10n.localeName.split('_').first) {
  'ko' => '다음에 심을 씨앗을 모았어요',
  'ja' => '次に植える種を集めました',
  _ => 'A seed saved for another day',
};
