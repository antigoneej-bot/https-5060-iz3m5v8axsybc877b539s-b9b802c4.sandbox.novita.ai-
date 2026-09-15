import 'gen/app_localizations.dart';

/// [TreeGrowth]의 성장 단계 인덱스를 다국어 라벨로 변환하는 UI 계층 헬퍼.
///
/// [TreeGrowth] 모델 자체는 여러 화면(choice_screen, garden_growth_share_sheet,
/// tree_growth_animation 등)에서 공유되므로 API를 바꾸지 않고, 이 함수를 통해
/// stageIndex -> 번역된 라벨 매핑만 UI 쪽에서 담당한다.
///
/// stageIndex -1: 아직 첫 단계에도 못 미침(씨앗), 0: 새싹, 1: 나무, 2: 꽃, 3: 열매.
String treeStageLabel(AppLocalizations l10n, int stageIndex) {
  switch (stageIndex) {
    case 0:
      return l10n.gardenTreeStageSprout;
    case 1:
      return l10n.gardenTreeStageTree;
    case 2:
      return l10n.gardenTreeStageFlower;
    case 3:
      return l10n.gardenTreeStageFruit;
    default:
      return l10n.gardenTreeStageSeed;
  }
}
