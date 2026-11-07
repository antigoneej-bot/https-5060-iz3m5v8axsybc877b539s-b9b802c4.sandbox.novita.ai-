import '../../l10n/app_language.dart';

/// Stable care types; each has a separate per-plant, per-day receipt.
enum PlantCare {
  water('물 주기', 3),
  fertilizer('거름 주기', 1),
  sunlight('햇볕 쬐기', 1);

  const PlantCare(this._label, this.growthPoints);
  final String _label;
  String get label => tr(_label);
  final int growthPoints;
}
