import '../services/emotion_insight_service.dart';
import 'emotion_l10n.dart';
import 'gen/app_localizations.dart';

/// [MonthlyObservationResult]를 언어별 한 줄 "이 달의 가벼운 분석" 문구로
/// 변환한다. [weeklyObservationText]와 같은 설계 원칙(언어중립 kind + 값을
/// 화면에서 문구로 완성)을 그대로 따른다.
String monthlyObservationText(
  AppLocalizations l10n,
  MonthlyObservationResult result,
) {
  switch (result.kind) {
    case MonthlyObservationKind.noData:
      return l10n.monthlyObservationNoData;
    case MonthlyObservationKind.improvedFromLastMonth:
      return l10n.monthlyObservationImprovedFromLastMonth(
        result.deltaPercent ?? 0,
      );
    case MonthlyObservationKind.declinedFromLastMonth:
      return l10n.monthlyObservationDeclinedFromLastMonth;
    case MonthlyObservationKind.dominantPositive:
      return l10n.monthlyObservationDominantPositive(
        result.emotion != null ? emotionLabel(l10n, result.emotion!.type) : '',
        result.percent ?? 0,
      );
    case MonthlyObservationKind.dominantNegative:
      return l10n.monthlyObservationDominantNegative(
        result.emotion != null ? emotionLabel(l10n, result.emotion!.type) : '',
        result.percent ?? 0,
      );
    case MonthlyObservationKind.diverseEmotions:
      return l10n.monthlyObservationDiverseEmotions(result.count ?? 0);
    case MonthlyObservationKind.mostlyHeavy:
      return l10n.monthlyObservationMostlyHeavy;
    case MonthlyObservationKind.defaultTopEmotion:
      return l10n.monthlyObservationDefaultTopEmotion(
        result.emotion != null ? emotionLabel(l10n, result.emotion!.type) : '',
        result.count ?? 0,
      );
    case MonthlyObservationKind.defaultThanks:
      return l10n.monthlyObservationDefaultThanks;
  }
}
