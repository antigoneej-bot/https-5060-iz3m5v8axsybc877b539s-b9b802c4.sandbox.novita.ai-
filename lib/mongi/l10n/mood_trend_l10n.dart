import '../services/emotion_insight_service.dart';
import 'gen/app_localizations.dart';

/// [MoodTrendSeries.direction]을 언어별 한 줄 관찰 문구로 변환한다.
/// [WeeklyObservationKind]/[WeekdayObservationKind]와 동일한 설계 원칙 -
/// 절대 "진단"하지 않고, 완만한 흐름 비교만 담담하게 알려준다.
String moodTrendDirectionText(AppLocalizations l10n, MoodTrendDirection kind) {
  switch (kind) {
    case MoodTrendDirection.notEnoughData:
      return l10n.moodTrendDirectionNotEnoughData;
    case MoodTrendDirection.improving:
      return l10n.moodTrendDirectionImproving;
    case MoodTrendDirection.steady:
      return l10n.moodTrendDirectionSteady;
    case MoodTrendDirection.declining:
      return l10n.moodTrendDirectionDeclining;
  }
}
