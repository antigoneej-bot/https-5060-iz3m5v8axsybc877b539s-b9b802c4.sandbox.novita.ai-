import '../models/emotion_trigger.dart';
import '../services/emotion_insight_service.dart';
import 'gen/app_localizations.dart';

/// [EmotionTrigger.label](한글 고정)은 하위 호환을 위해 그대로 두고,
/// 화면에서는 이 함수로 id 기준 언어별 이름을 구한다.
String emotionTriggerLabel(AppLocalizations l10n, String triggerId) {
  switch (triggerId) {
    case 'work_study':
      return l10n.emotionTriggerWorkStudy;
    case 'relationship':
      return l10n.emotionTriggerRelationship;
    case 'family':
      return l10n.emotionTriggerFamily;
    case 'health':
      return l10n.emotionTriggerHealth;
    case 'money':
      return l10n.emotionTriggerMoney;
    case 'sleep':
      return l10n.emotionTriggerSleep;
    case 'alone':
      return l10n.emotionTriggerAlone;
    case 'sns':
      return l10n.emotionTriggerSns;
    case 'weather':
      return l10n.emotionTriggerWeather;
    case 'future':
      return l10n.emotionTriggerFuture;
    case 'achievement':
      return l10n.emotionTriggerAchievement;
    case 'etc':
    default:
      return l10n.emotionTriggerEtc;
  }
}

/// [EmotionTrigger]의 emoji + 언어별 label을 합친 짧은 표시용 문자열.
String emotionTriggerDisplay(AppLocalizations l10n, EmotionTrigger trigger) {
  return '${trigger.emoji} ${emotionTriggerLabel(l10n, trigger.id)}';
}

/// [EmotionInsightService.buildTriggerInsightKind]가 돌려준 종류(+ 값)를
/// 실제 번역 문자열로 바꾼다.
String triggerInsightText(AppLocalizations l10n, TriggerInsightResult r) {
  final triggerLabel = emotionTriggerLabel(l10n, r.trigger.id);
  switch (r.kind) {
    case TriggerInsightKind.dominantNegativeCause:
      return l10n.triggerInsightDominantNegativeCause(triggerLabel, r.count);
    case TriggerInsightKind.topTrigger:
      return l10n.triggerInsightTopTrigger(triggerLabel, r.count);
  }
}
