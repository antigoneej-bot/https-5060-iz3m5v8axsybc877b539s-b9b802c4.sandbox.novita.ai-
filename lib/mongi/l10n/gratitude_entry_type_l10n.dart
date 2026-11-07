import 'gen/app_localizations.dart';
import '../models/gratitude_entry_type.dart';

/// [GratitudeEntryType.label]/[.hint]/[.placeholder]는 하위 호환을 위해
/// 한글로 고정되어 있다 - 화면에서는 이 헬퍼를 통해 [AppLocalizations]
/// 기반의 다국어 문구로 바꿔서 표시한다.
String gratitudeEntryTypeLabel(AppLocalizations l10n, GratitudeEntryType type) {
  switch (type) {
    case GratitudeEntryType.gratitude:
      return l10n.gratitudeEntryTypeLabelGratitude;
    case GratitudeEntryType.achievement:
      return l10n.gratitudeEntryTypeLabelAchievement;
  }
}

/// [GratitudeEntryType.hint]의 다국어 버전.
String gratitudeEntryTypeHint(AppLocalizations l10n, GratitudeEntryType type) {
  switch (type) {
    case GratitudeEntryType.gratitude:
      return l10n.gratitudeEntryTypeHintGratitude;
    case GratitudeEntryType.achievement:
      return l10n.gratitudeEntryTypeHintAchievement;
  }
}

/// [GratitudeEntryType.placeholder]의 다국어 버전.
String gratitudeEntryTypePlaceholder(
  AppLocalizations l10n,
  GratitudeEntryType type,
) {
  switch (type) {
    case GratitudeEntryType.gratitude:
      return l10n.gratitudeEntryTypePlaceholderGratitude;
    case GratitudeEntryType.achievement:
      return l10n.gratitudeEntryTypePlaceholderAchievement;
  }
}
