import 'gen/app_localizations.dart';

/// `_CardFrame` in `emotion_share_sheet.dart` is a `static const` list, so its
/// `label` field cannot be resolved via `AppLocalizations` at declaration
/// time (no BuildContext available for const evaluation). This helper maps
/// a frame's stable `id` to its localized label at build time instead.
String shareFrameLabel(AppLocalizations l10n, String frameId) {
  switch (frameId) {
    case 'default':
      return l10n.shareFrameLabelDefault;
    case 'cherry':
      return l10n.shareFrameLabelCherry;
    case 'gold':
      return l10n.shareFrameLabelGold;
    default:
      return frameId;
  }
}
