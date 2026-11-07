import '../services/emotion_insight_service.dart';
import 'gen/app_localizations.dart';

/// [WeekdayStat.weekdayIndex](일=0 ... 토=6)에 해당하는 언어별 요일 이름을
/// 돌려준다. [EmotionInsightService]의 `label` 필드(한글 고정)는 하위
/// 호환을 위해 그대로 두고, 화면에서는 이 함수로 언어별 이름을 구한다.
String weekdayLabel(AppLocalizations l10n, int weekdayIndex) {
  switch (weekdayIndex) {
    case 0:
      return l10n.weekdaySun;
    case 1:
      return l10n.weekdayMon;
    case 2:
      return l10n.weekdayTue;
    case 3:
      return l10n.weekdayWed;
    case 4:
      return l10n.weekdayThu;
    case 5:
      return l10n.weekdayFri;
    default:
      return l10n.weekdaySat;
  }
}

/// [WeekdayObservationResult]를 언어별 한 줄 관찰 문구로 변환한다.
String weekdayObservationText(
  AppLocalizations l10n,
  WeekdayObservationResult result,
) {
  switch (result.kind) {
    case WeekdayObservationKind.notEnoughData:
      return l10n.weekdayObservationNotEnoughData;
    case WeekdayObservationKind.hasPattern:
      return l10n.weekdayObservationHasPattern(
        weekdayLabel(l10n, result.bestDay!.weekdayIndex),
        weekdayLabel(l10n, result.toughestDay!.weekdayIndex),
      );
    case WeekdayObservationKind.noClearPattern:
      return l10n.weekdayObservationNoClearPattern;
  }
}
