import 'gen/app_localizations.dart';

/// [SeasonPass]의 "마음 마일스톤"(5의 배수 레벨) 격려 문구를 다국어로
/// 번역해서 돌려준다. 실제 판단 기준(어떤 레벨이 마일스톤인지)은
/// [SeasonPass.isMindMilestone]에 그대로 남아 있고, 여기서는 그 레벨에 맞는
/// 문구만 골라 붙인다 - [MongiMoodService]/[AppLocalizations] 조합과 동일한
/// 설계 원칙이다.
String seasonMilestoneText(AppLocalizations l10n, int level) {
  switch (level) {
    case 5:
      return l10n.seasonMilestoneLevel5;
    case 10:
      return l10n.seasonMilestoneLevel10;
    case 15:
      return l10n.seasonMilestoneLevel15;
    case 20:
      return l10n.seasonMilestoneLevel20;
    default:
      return '';
  }
}
