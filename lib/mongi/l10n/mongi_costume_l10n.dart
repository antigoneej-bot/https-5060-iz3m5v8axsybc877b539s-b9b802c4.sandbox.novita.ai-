import '../models/mongi_costume.dart';
import 'gen/app_localizations.dart';

/// [CostumeRarity]의 등급 표시 라벨을 다국어 문자열로 변환하는 UI 계층 헬퍼.
/// (모델 자체는 BuildContext/AppLocalizations에 접근할 수 없으므로, 호출부에서
/// 번역이 필요한 위치마다 이 함수를 사용한다. [MongiCostume.rarityLabel]은
/// 하위 호환을 위해 하드코딩된 한국어 버전으로 그대로 남겨둔다.)
String costumeRarityLabel(AppLocalizations l10n, CostumeRarity r) {
  switch (r) {
    case CostumeRarity.common:
      return l10n.mindBoxRarityCommon;
    case CostumeRarity.rare:
      return l10n.mindBoxRarityRare;
    case CostumeRarity.epic:
      return l10n.mindBoxRarityEpic;
    case CostumeRarity.legendary:
      return l10n.mindBoxRarityLegendary;
  }
}

/// [MongiCostume.name]은 하위 호환을 위해 한글로 고정되어 있다 - 화면에서는
/// 이 헬퍼를 통해 [AppLocalizations] 기반의 다국어 이름으로 바꿔서 표시한다.
String costumeName(AppLocalizations l10n, MongiCostume costume) {
  switch (costume.id) {
    case 'ribbon':
      return l10n.mongiCostumeNameRibbon;
    case 'star_band':
      return l10n.mongiCostumeNameStarBand;
    case 'scarf':
      return l10n.mongiCostumeNameScarf;
    case 'bunny_ears':
      return l10n.mongiCostumeNameBunnyEars;
    case 'flower_crown':
      return l10n.mongiCostumeNameFlowerCrown;
    case 'wizard_hat':
      return l10n.mongiCostumeNameWizardHat;
    case 'golden_crown':
      return l10n.mongiCostumeNameGoldenCrown;
    case 'cloud_band':
      return l10n.mongiCostumeNameCloudBand;
    case 'sunflower_band':
      return l10n.mongiCostumeNameSunflowerBand;
    case 'angel_wings':
      return l10n.mongiCostumeNameAngelWings;
    case 'pirate_hat':
      return l10n.mongiCostumeNamePirateHat;
    case 'galaxy_cape':
      return l10n.mongiCostumeNameGalaxyCape;
    case 'phoenix_crown':
      return l10n.mongiCostumeNamePhoenixCrown;
    case 'saekdong_ribbon':
      return l10n.mongiCostumeNameSaekdongRibbon;
    case 'bokjumeoni':
      return l10n.mongiCostumeNameBokjumeoni;
    case 'sprout_hat':
      return l10n.mongiCostumeNameSproutHat;
    default:
      return costume.name;
  }
}
