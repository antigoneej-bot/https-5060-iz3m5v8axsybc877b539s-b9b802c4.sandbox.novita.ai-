import 'gen/app_localizations.dart';
import '../models/garden_decoration.dart';

/// [GardenDecoration.label]은 하위 호환을 위해 한글로 고정되어 있다 - 화면에서는
/// 이 헬퍼를 통해 [AppLocalizations] 기반의 다국어 이름으로 바꿔서 표시한다.
String decorationLabel(AppLocalizations l10n, GardenDecoration decoration) {
  switch (decoration.id) {
    case 'bench':
      return l10n.gardenDecoLabelBench;
    case 'path':
      return l10n.gardenDecoLabelPath;
    case 'fountain':
      return l10n.gardenDecoLabelFountain;
    case 'lantern':
      return l10n.gardenDecoLabelLantern;
    case 'rainbow_fence':
      return l10n.gardenDecoLabelRainbowFence;
    case 'star_light':
      return l10n.gardenDecoLabelStarLight;
    case 'wind_chime':
      return l10n.gardenDecoLabelWindChime;
    case 'butterfly_garden':
      return l10n.gardenDecoLabelButterflyGarden;
    case 'gazebo':
      return l10n.gardenDecoLabelGazebo;
    case 'lotus_pond':
      return l10n.gardenDecoLabelLotusPond;
    case 'jangdokdae':
      return l10n.gardenDecoLabelJangdokdae;
    case 'ginkgo_path':
      return l10n.gardenDecoLabelGinkgoPath;
    case 'hanok_lantern':
      return l10n.gardenDecoLabelHanokLantern;
    default:
      return decoration.label;
  }
}

/// [GardenDecoration.unlockHint]의 다국어 버전. 프리미엄 아이템은 전부
/// 동일한 "장식팩 구매" 안내 문구를 공유한다.
String decorationUnlockHint(
  AppLocalizations l10n,
  GardenDecoration decoration,
) {
  if (decoration.isPremium) {
    return l10n.gardenDecoUnlockHintPremiumPack;
  }
  switch (decoration.id) {
    case 'bench':
      return l10n.gardenDecoUnlockHintBench;
    case 'path':
      return l10n.gardenDecoUnlockHintPath;
    case 'fountain':
      return l10n.gardenDecoUnlockHintFountain;
    case 'wind_chime':
      return l10n.gardenDecoUnlockHintWindChime;
    case 'butterfly_garden':
      return l10n.gardenDecoUnlockHintButterflyGarden;
    case 'jangdokdae':
      return l10n.gardenDecoUnlockHintJangdokdae;
    case 'ginkgo_path':
      return l10n.gardenDecoUnlockHintGinkgoPath;
    default:
      return decoration.unlockHint;
  }
}

/// [GardenDecoration] 잠금 해제 진행 상황을 다국어 문구로 변환하는 UI 계층 헬퍼.
///
/// [GardenProvider]는 상태(streakDays/progress/seedCounts)만 갖고 있고
/// AppLocalizations에 의존하지 않으므로, "3일 연속 중 1일째"와 같은 진행
/// 문구는 이 헬퍼에서 원시 상태를 받아 조립한다. 프리미엄 아이템이거나 이미
/// 잠금 해제된 경우 null을 반환한다.
String? decorationProgressLabel(
  AppLocalizations l10n, {
  required GardenDecoration decoration,
  required bool isUnlocked,
  required int streakDays,
  required double progress,
  required Map<String, int> seedCounts,
}) {
  if (decoration.isPremium || isUnlocked) return null;
  switch (decoration.id) {
    case 'bench':
      return l10n.gardenDecoProgressBench(streakDays.clamp(0, 3));
    case 'path':
      return l10n.gardenDecoProgressPath((progress * 100).round());
    case 'fountain':
      const seedIds = ['forgiveness', 'love', 'peace'];
      final seedLabels = {
        'forgiveness': l10n.gardenSeedNameForgiveness,
        'love': l10n.gardenSeedNameLove,
        'peace': l10n.gardenSeedNamePeace,
      };
      final planted = seedIds.where((id) => (seedCounts[id] ?? 0) > 0).length;
      final missing = seedIds
          .where((id) => (seedCounts[id] ?? 0) == 0)
          .map((id) => seedLabels[id])
          .join(', ');
      return missing.isNotEmpty
          ? l10n.gardenDecoProgressFountainWithMissing(planted, missing)
          : l10n.gardenDecoProgressFountainPlanted(planted);
    default:
      return null;
  }
}
