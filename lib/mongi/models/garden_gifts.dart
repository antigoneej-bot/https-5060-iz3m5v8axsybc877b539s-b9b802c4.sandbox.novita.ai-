const gardenFlowerNames = {
  'daisy': '데이지',
  'tulip': '튤립',
  'hydrangea': '수국',
  'gypsophila': '안개꽃',
  'lavender': '라벤더',
};
const gardenReactionNames = {
  'heart': '하트',
  'star': '별',
  'hug': '포옹',
  'butterfly': '나비',
};
const gardenReactionEmoji = {
  'heart': '💗',
  'star': '⭐',
  'hug': '🫂',
  'butterfly': '🦋',
};

class GardenReaction {
  final String kind;
  final DateTime expiresAt;
  const GardenReaction(this.kind, this.expiresAt);
  bool activeAt(DateTime now) =>
      gardenReactionNames.containsKey(kind) && now.isBefore(expiresAt);
  static GardenReaction? fromJson(dynamic raw) {
    if (raw is! Map || !gardenReactionNames.containsKey(raw['kind']))
      return null;
    final date = DateTime.tryParse(raw['expiresAt']?.toString() ?? '');
    return date == null ? null : GardenReaction(raw['kind'] as String, date);
  }
}
