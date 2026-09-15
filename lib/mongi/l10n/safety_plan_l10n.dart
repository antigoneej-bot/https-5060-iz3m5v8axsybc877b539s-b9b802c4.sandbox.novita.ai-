import '../models/safety_plan.dart';
import 'gen/app_localizations.dart';

/// [SafetyPlanSection]의 title/hint/placeholder는 모델 안에 하드코딩된
/// 한국어 문자열(하위 호환용 기본값)로 남아있고, 실제 화면 표시는 이 헬퍼가
/// id를 기준으로 [AppLocalizations]에서 번역된 문자열을 골라 대신 돌려준다.
/// (다른 l10n 헬퍼 - emotionTriggerLabel 등 - 와 동일한 패턴.)
String safetyPlanSectionTitle(AppLocalizations l10n, String sectionId) {
  switch (sectionId) {
    case 'warning_signs':
      return l10n.safetyPlanSectionWarningSignsTitle;
    case 'coping_strategies':
      return l10n.safetyPlanSectionCopingStrategiesTitle;
    case 'support_people':
      return l10n.safetyPlanSectionSupportPeopleTitle;
    case 'safe_place':
      return l10n.safetyPlanSectionSafePlaceTitle;
    case 'reasons_to_live':
    default:
      return l10n.safetyPlanSectionReasonsToLiveTitle;
  }
}

String safetyPlanSectionHint(AppLocalizations l10n, String sectionId) {
  switch (sectionId) {
    case 'warning_signs':
      return l10n.safetyPlanSectionWarningSignsHint;
    case 'coping_strategies':
      return l10n.safetyPlanSectionCopingStrategiesHint;
    case 'support_people':
      return l10n.safetyPlanSectionSupportPeopleHint;
    case 'safe_place':
      return l10n.safetyPlanSectionSafePlaceHint;
    case 'reasons_to_live':
    default:
      return l10n.safetyPlanSectionReasonsToLiveHint;
  }
}

String safetyPlanSectionPlaceholder(AppLocalizations l10n, String sectionId) {
  switch (sectionId) {
    case 'warning_signs':
      return l10n.safetyPlanSectionWarningSignsPlaceholder;
    case 'coping_strategies':
      return l10n.safetyPlanSectionCopingStrategiesPlaceholder;
    case 'support_people':
      return l10n.safetyPlanSectionSupportPeoplePlaceholder;
    case 'safe_place':
      return l10n.safetyPlanSectionSafePlacePlaceholder;
    case 'reasons_to_live':
    default:
      return l10n.safetyPlanSectionReasonsToLivePlaceholder;
  }
}

/// [SafetyPlanSection.all]을 순회할 때 title/hint/placeholder 세 값을 한 번에
/// 얻고 싶을 때 쓰는 편의 함수 - 화면 쪽 호출을 짧게 유지한다.
class SafetyPlanSectionText {
  final String title;
  final String hint;
  final String placeholder;

  const SafetyPlanSectionText({
    required this.title,
    required this.hint,
    required this.placeholder,
  });
}

SafetyPlanSectionText safetyPlanSectionText(
  AppLocalizations l10n,
  SafetyPlanSection section,
) {
  return SafetyPlanSectionText(
    title: safetyPlanSectionTitle(l10n, section.id),
    hint: safetyPlanSectionHint(l10n, section.id),
    placeholder: safetyPlanSectionPlaceholder(l10n, section.id),
  );
}
