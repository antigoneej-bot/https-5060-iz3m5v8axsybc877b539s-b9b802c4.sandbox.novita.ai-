/// Stable care types; each has a separate per-plant, per-day receipt.
enum PlantCare {
  water('물 주기', 3),
  fertilizer('거름 주기', 1),
  sunlight('햇볕 쬐기', 1);

  const PlantCare(this.label, this.growthPoints);
  final String label;
  final int growthPoints;
}
