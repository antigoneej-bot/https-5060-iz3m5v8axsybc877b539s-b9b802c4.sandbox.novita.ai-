import '../services/mongi_letter_service.dart';
import 'gen/app_localizations.dart';

/// [MongiLetterBodyResult]를 언어별 편지 본문 문단으로 변환한다.
String mongiLetterBodyText(
  AppLocalizations l10n,
  MongiLetterBodyResult result,
) {
  switch (result.kind) {
    case MongiLetterBodyKind.topTarget:
      return l10n.mongiLetterBodyTopTarget(result.target ?? '');
    case MongiLetterBodyKind.topEmotion:
      return l10n.mongiLetterBodyTopEmotion(result.emotion?.label ?? '');
    case MongiLetterBodyKind.manyNotes:
      return l10n.mongiLetterBodyManyNotes;
    case MongiLetterBodyKind.mostlyPositive:
      return l10n.mongiLetterBodyMostlyPositive;
    case MongiLetterBodyKind.mostlyHeavy:
      return l10n.mongiLetterBodyMostlyHeavy;
    case MongiLetterBodyKind.defaultThanks:
      return l10n.mongiLetterBodyDefaultThanks;
  }
}

/// [MongiLetterStreakResult]를 언어별 마무리 격려 문단으로 변환한다.
String mongiLetterStreakText(
  AppLocalizations l10n,
  MongiLetterStreakResult result,
) {
  switch (result.kind) {
    case MongiLetterStreakKind.longStreak:
      return l10n.mongiLetterStreakLong(result.streak);
    case MongiLetterStreakKind.shortStreak:
      return l10n.mongiLetterStreakShort(result.streak);
    case MongiLetterStreakKind.noStreak:
      return l10n.mongiLetterStreakNone;
  }
}
