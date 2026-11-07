import '../l10n/emotion_l10n.dart';
import '../l10n/emotion_trigger_l10n.dart';
import '../l10n/weekday_l10n.dart';
import '../services/mind_reflection_service.dart';
import 'gen/app_localizations.dart';

/// [MindReflectionInsight]를 언어별 한 줄(또는 여러 줄) 문구로 변환한다.
String mindReflectionInsightText(
  AppLocalizations l10n,
  MindReflectionInsight insight,
) {
  switch (insight.kind) {
    case MindReflectionInsightKind.emotionWeekdayLink:
      return l10n.mindReflectionEmotionWeekdayLink(
        emotionLabel(l10n, insight.emotion!.type),
        weekdayLabel(l10n, insight.weekdayIndex!),
        insight.count!,
      );
    case MindReflectionInsightKind.triggerNegativeLink:
      return l10n.mindReflectionTriggerNegativeLink(
        emotionTriggerLabel(l10n, insight.trigger!.id),
        insight.count!,
      );
    case MindReflectionInsightKind.growthSignal:
      return l10n.mindReflectionGrowthSignal(
        emotionLabel(l10n, insight.emotion!.type),
      );
    case MindReflectionInsightKind.gratitudeMoodLink:
      return l10n.mindReflectionGratitudeMoodLink;
    case MindReflectionInsightKind.consistencySignal:
      return l10n.mindReflectionConsistencySignal(insight.streak!);
    case MindReflectionInsightKind.defaultObservation:
      return l10n.mindReflectionDefaultObservation;
  }
}
