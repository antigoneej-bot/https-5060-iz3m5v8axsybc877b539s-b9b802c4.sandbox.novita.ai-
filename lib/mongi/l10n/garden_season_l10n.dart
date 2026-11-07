import '../models/garden_season.dart';
import 'gen/app_localizations.dart';

/// [GardenSeason]의 계절 이름/인사말을 다국어 문자열로 변환하는 UI 계층 헬퍼.
/// (모델 자체는 BuildContext/AppLocalizations에 접근할 수 없으므로, 호출부에서
/// 번역이 필요한 위치마다 이 함수를 사용한다.)
String gardenSeasonLabel(AppLocalizations l10n, GardenSeason season) {
  switch (season) {
    case GardenSeason.spring:
      return l10n.gardenSeasonSpring;
    case GardenSeason.summer:
      return l10n.gardenSeasonSummer;
    case GardenSeason.autumn:
      return l10n.gardenSeasonAutumn;
    case GardenSeason.winter:
      return l10n.gardenSeasonWinter;
  }
}

String gardenSeasonGreeting(AppLocalizations l10n, GardenSeason season) {
  switch (season) {
    case GardenSeason.spring:
      return l10n.gardenSeasonGreetingSpring;
    case GardenSeason.summer:
      return l10n.gardenSeasonGreetingSummer;
    case GardenSeason.autumn:
      return l10n.gardenSeasonGreetingAutumn;
    case GardenSeason.winter:
      return l10n.gardenSeasonGreetingWinter;
  }
}
