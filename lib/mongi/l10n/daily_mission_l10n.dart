import 'gen/app_localizations.dart';
import '../models/daily_mission.dart';

/// [DailyMissionDef.label]은 저장소/진행도 로직에서 공유되는 고정 id 기준
/// 데이터라 한국어로 하드코딩돼 있다. 화면에 보여줄 다국어 라벨은 이 헬퍼가
/// 미션 id를 기준으로 번역해서 돌려준다.
String dailyMissionLabel(AppLocalizations l10n, DailyMissionDef mission) {
  switch (mission.id) {
    case 'eat_emotions':
      return l10n.dailyMissionLabelEatEmotions(mission.target);
    case 'complete_stage':
      return l10n.dailyMissionLabelCompleteStage(mission.target);
    case 'plant_love':
      return l10n.dailyMissionLabelPlantLove(mission.target);
    default:
      return mission.label;
  }
}
