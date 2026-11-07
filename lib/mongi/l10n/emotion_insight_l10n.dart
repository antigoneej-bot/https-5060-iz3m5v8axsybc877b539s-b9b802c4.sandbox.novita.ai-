import '../services/emotion_insight_service.dart';
import 'gen/app_localizations.dart';

/// [EmotionInsightService.buildSessionInsightKind]가 돌려준 종류(+ 값)를
/// 실제 번역 문자열로 바꾼다. [MongiMoodService]와 동일한 설계 원칙 -
/// 서비스는 "종류"만 계산하고, 화면(정확히는 이 헬퍼)이 [AppLocalizations]로
/// 언어별 문구를 완성한다.
String sessionInsightText(AppLocalizations l10n, SessionInsightResult r) {
  switch (r.kind) {
    case SessionInsightKind.frequentPositive:
      return l10n.choiceInsightFrequentPositive(r.count ?? 0);
    case SessionInsightKind.frequentNegative:
      return l10n.choiceInsightFrequentNegative(r.count ?? 0);
    case SessionInsightKind.allPositive:
      return l10n.choiceInsightAllPositive;
    case SessionInsightKind.longAbsence:
      return l10n.choiceInsightLongAbsence(r.emotion?.label ?? '', r.days ?? 0);
    case SessionInsightKind.firstEncounter:
      return l10n.choiceInsightFirstEncounter(r.emotion?.label ?? '');
  }
}

/// [EmotionInsightService.buildNextGoalHintKind]가 돌려준 종류(+ 값)를
/// 실제 번역 문자열로 바꾼다.
String nextGoalHintText(AppLocalizations l10n, NextGoalHintResult r) {
  switch (r.kind) {
    case NextGoalHintKind.almostCollected:
      return l10n.choiceNextGoalAlmostCollected(r.count);
    case NextGoalHintKind.treeAlmost:
      return l10n.choiceNextGoalTreeAlmost(r.count);
    case NextGoalHintKind.manyUncollected:
      return l10n.choiceNextGoalManyUncollected(r.count);
  }
}

/// [EmotionInsightService.buildComebackCareKind]가 돌려준 종류(+ 며칠 만인지)를
/// 실제 번역 문자열로 바꾼다. 홈 화면 "복귀 케어" 카드에서 사용한다.
String comebackCareTitle(AppLocalizations l10n, ComebackCareResult r) {
  switch (r.kind) {
    case ComebackCareKind.shortBreak:
      return l10n.homeComebackCareTitleShort;
    case ComebackCareKind.longBreak:
      return l10n.homeComebackCareTitleLong;
  }
}

String comebackCareBody(AppLocalizations l10n, ComebackCareResult r) {
  switch (r.kind) {
    case ComebackCareKind.shortBreak:
      return l10n.homeComebackCareBodyShort(r.days);
    case ComebackCareKind.longBreak:
      return l10n.homeComebackCareBodyLong(r.days);
  }
}
