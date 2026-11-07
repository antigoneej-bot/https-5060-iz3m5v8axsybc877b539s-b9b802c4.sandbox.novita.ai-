import '../services/emotion_insight_service.dart';
import 'gen/app_localizations.dart';

/// [WeeklyObservationResult]를 언어별 한 줄 관찰 문구로 변환한다.
String weeklyObservationText(
  AppLocalizations l10n,
  WeeklyObservationResult result,
) {
  switch (result.kind) {
    case WeeklyObservationKind.noData:
      return l10n.weeklyObservationNoData;
    case WeeklyObservationKind.improvedFromLastWeek:
      return l10n.weeklyObservationImprovedFromLastWeek(
        result.deltaPercent ?? 0,
      );
    case WeeklyObservationKind.declinedFromLastWeek:
      return l10n.weeklyObservationDeclinedFromLastWeek;
    case WeeklyObservationKind.dominantPositive:
      return l10n.weeklyObservationDominantPositive(
        result.emotion?.label ?? '',
      );
    case WeeklyObservationKind.dominantNegative:
      return l10n.weeklyObservationDominantNegative(
        result.emotion?.label ?? '',
      );
    case WeeklyObservationKind.manyNotes:
      return l10n.weeklyObservationManyNotes;
    case WeeklyObservationKind.mostlyHeavy:
      return l10n.weeklyObservationMostlyHeavy;
    case WeeklyObservationKind.defaultTopEmotion:
      return l10n.weeklyObservationDefaultTopEmotion(
        result.emotion?.label ?? '',
        result.count ?? 0,
      );
    case WeeklyObservationKind.defaultThanks:
      return l10n.weeklyObservationDefaultThanks;
  }
}
