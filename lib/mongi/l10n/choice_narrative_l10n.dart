import 'gen/app_localizations.dart';

/// [GameNarrativeService]의 콤보/조기종료 후크 문구를 다국어로 번역해서
/// 돌려주는 UI 레이어 헬퍼. 서비스 자체는 위젯/BuildContext에 접근할 수 없어
/// 여전히 한국어 문자열을 직접 반환하므로(다른 미번역 화면들이 그대로
/// 사용 중), 여기서는 서비스와 동일한 분기 기준만 재사용해 번역된 문자열을
/// 새로 만든다.
///
/// 기준(서비스와 동일하게 유지):
/// - comboNarrative: maxCombo < 5 → low, < 10 → mid, 그 외 → high
/// - earlyStopHook: remaining이 null이 아니고 0보다 크면 "남음" 버전
String comboNarrativeText(AppLocalizations l10n, int maxCombo) {
  if (maxCombo < 5) {
    return l10n.choiceComboLow(maxCombo);
  }
  if (maxCombo < 10) {
    return l10n.choiceComboMid(maxCombo);
  }
  return l10n.choiceComboHigh(maxCombo);
}

String earlyStopHookText(
  AppLocalizations l10n, {
  required int eatenCount,
  int? remaining,
}) {
  if (remaining != null && remaining > 0) {
    return l10n.choiceEarlyStopWithRemaining(eatenCount, remaining);
  }
  return l10n.choiceEarlyStopNoRemaining(eatenCount);
}
