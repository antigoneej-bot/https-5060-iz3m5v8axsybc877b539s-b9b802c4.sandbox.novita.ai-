import '../models/mongi_costume.dart';
import '../models/season_pass.dart';
import 'gen/app_localizations.dart';
import 'mongi_costume_l10n.dart';

/// [SeasonRewardItem.label]은 한국어로 미리 조합된 const 문자열이라 그대로
/// 쓸 수 없다. 대신 이 헬퍼가 [SeasonRewardItem]의 숫자 필드(lightEssence/
/// starShard/costumeId)만 읽어 언어에 맞는 라벨을 다시 조합한다 - 기존
/// `.label` 필드는 하위 호환을 위해 그대로 두고 건드리지 않는다.
String seasonRewardLabel(AppLocalizations l10n, SeasonRewardItem reward) {
  if (reward.costumeId != null) {
    final resolvedCostumeName = costumeName(
      l10n,
      MongiCostume.byId(reward.costumeId!),
    );
    return l10n.seasonRewardFinaleLabel(
      reward.lightEssence,
      reward.starShard,
      resolvedCostumeName,
    );
  }
  if (reward.starShard > 0) {
    return l10n.seasonRewardWithShardLabel(
      reward.lightEssence,
      reward.starShard,
    );
  }
  return l10n.seasonRewardLightOnlyLabel(reward.lightEssence);
}
