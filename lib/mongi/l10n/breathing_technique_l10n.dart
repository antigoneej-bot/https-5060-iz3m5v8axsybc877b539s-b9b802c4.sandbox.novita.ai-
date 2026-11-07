import 'gen/app_localizations.dart';
import '../models/breathing_technique.dart';

/// [BreathingTechniqueDef.name]/[.description]은 저장소/로직 공유를 위해
/// 한국어로 하드코딩돼 있다. 화면에서는 이 헬퍼들을 통해 [AppLocalizations]
/// 기반의 다국어 문구로 바꿔서 표시한다.
String breathingTechniqueName(
  AppLocalizations l10n,
  BreathingTechniqueDef def,
) {
  switch (def.id) {
    case BreathingTechniqueId.calmBreath:
      return l10n.breathingTechniqueNameCalmBreath;
    case BreathingTechniqueId.anxietyRelief:
      return l10n.breathingTechniqueNameAnxietyRelief;
    case BreathingTechniqueId.boxBreathing:
      return l10n.breathingTechniqueNameBoxBreathing;
    case BreathingTechniqueId.sleepWindDown:
      return l10n.breathingTechniqueNameSleepWindDown;
    case BreathingTechniqueId.energizingBreath:
      return l10n.breathingTechniqueNameEnergizingBreath;
  }
}

String breathingTechniqueDescription(
  AppLocalizations l10n,
  BreathingTechniqueDef def,
) {
  switch (def.id) {
    case BreathingTechniqueId.calmBreath:
      return l10n.breathingTechniqueDescCalmBreath;
    case BreathingTechniqueId.anxietyRelief:
      return l10n.breathingTechniqueDescAnxietyRelief;
    case BreathingTechniqueId.boxBreathing:
      return l10n.breathingTechniqueDescBoxBreathing;
    case BreathingTechniqueId.sleepWindDown:
      return l10n.breathingTechniqueDescSleepWindDown;
    case BreathingTechniqueId.energizingBreath:
      return l10n.breathingTechniqueDescEnergizingBreath;
  }
}
