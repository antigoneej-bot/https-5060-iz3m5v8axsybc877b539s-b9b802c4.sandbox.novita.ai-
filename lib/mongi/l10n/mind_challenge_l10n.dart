import 'gen/app_localizations.dart';
import '../models/mind_challenge.dart';

/// [MindChallengeDef.title]/[.description]/[.dailyPrompts]는 저장소/진행도
/// 로직에서 id 기준으로 공유되는 고정 데이터라 한국어로 하드코딩돼 있다.
/// 화면에서는 이 헬퍼들을 통해 [AppLocalizations] 기반의 다국어 문구로
/// 바꿔서 표시한다.
String mindChallengeTitle(AppLocalizations l10n, MindChallengeDef def) {
  switch (def.id) {
    case 'self_esteem':
      return l10n.mindChallengeTitleSelfEsteem;
    case 'anxiety_calm':
      return l10n.mindChallengeTitleAnxietyCalm;
    case 'burnout_recovery':
      return l10n.mindChallengeTitleBurnoutRecovery;
    case 'gratitude_habit':
      return l10n.mindChallengeTitleGratitudeHabit;
    default:
      return def.title;
  }
}

String mindChallengeDescription(AppLocalizations l10n, MindChallengeDef def) {
  switch (def.id) {
    case 'self_esteem':
      return l10n.mindChallengeDescSelfEsteem;
    case 'anxiety_calm':
      return l10n.mindChallengeDescAnxietyCalm;
    case 'burnout_recovery':
      return l10n.mindChallengeDescBurnoutRecovery;
    case 'gratitude_habit':
      return l10n.mindChallengeDescGratitudeHabit;
    default:
      return def.description;
  }
}

/// [dayIndex]는 1부터 시작(1일차, 2일차, ...).
String mindChallengeDailyPrompt(
  AppLocalizations l10n,
  MindChallengeDef def,
  int dayIndex,
) {
  switch (def.id) {
    case 'self_esteem':
      switch (dayIndex) {
        case 1:
          return l10n.mindChallengeDaySelfEsteem1;
        case 2:
          return l10n.mindChallengeDaySelfEsteem2;
        case 3:
          return l10n.mindChallengeDaySelfEsteem3;
        case 4:
          return l10n.mindChallengeDaySelfEsteem4;
        case 5:
          return l10n.mindChallengeDaySelfEsteem5;
        case 6:
          return l10n.mindChallengeDaySelfEsteem6;
        case 7:
          return l10n.mindChallengeDaySelfEsteem7;
      }
    case 'anxiety_calm':
      switch (dayIndex) {
        case 1:
          return l10n.mindChallengeDayAnxietyCalm1;
        case 2:
          return l10n.mindChallengeDayAnxietyCalm2;
        case 3:
          return l10n.mindChallengeDayAnxietyCalm3;
        case 4:
          return l10n.mindChallengeDayAnxietyCalm4;
        case 5:
          return l10n.mindChallengeDayAnxietyCalm5;
        case 6:
          return l10n.mindChallengeDayAnxietyCalm6;
        case 7:
          return l10n.mindChallengeDayAnxietyCalm7;
      }
    case 'burnout_recovery':
      switch (dayIndex) {
        case 1:
          return l10n.mindChallengeDayBurnoutRecovery1;
        case 2:
          return l10n.mindChallengeDayBurnoutRecovery2;
        case 3:
          return l10n.mindChallengeDayBurnoutRecovery3;
        case 4:
          return l10n.mindChallengeDayBurnoutRecovery4;
        case 5:
          return l10n.mindChallengeDayBurnoutRecovery5;
        case 6:
          return l10n.mindChallengeDayBurnoutRecovery6;
        case 7:
          return l10n.mindChallengeDayBurnoutRecovery7;
      }
    case 'gratitude_habit':
      switch (dayIndex) {
        case 1:
          return l10n.mindChallengeDayGratitudeHabit1;
        case 2:
          return l10n.mindChallengeDayGratitudeHabit2;
        case 3:
          return l10n.mindChallengeDayGratitudeHabit3;
        case 4:
          return l10n.mindChallengeDayGratitudeHabit4;
        case 5:
          return l10n.mindChallengeDayGratitudeHabit5;
        case 6:
          return l10n.mindChallengeDayGratitudeHabit6;
        case 7:
          return l10n.mindChallengeDayGratitudeHabit7;
      }
  }
  final idx = dayIndex - 1;
  if (idx >= 0 && idx < def.dailyPrompts.length) return def.dailyPrompts[idx];
  return '';
}
