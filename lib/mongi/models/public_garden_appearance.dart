import 'dart:convert';

/// Compare only the appearance that a visitor can see. Personal memories,
/// letter text and mood statistics are deliberately outside this model.
class PublicGardenAppearance {
  static const _keys = {
    'seedCounts',
    'equippedDecorationIds',
    'treeStageIndex',
    'memoryTreeStage',
    'hasCheerFlowers',
    'flowerKinds',
    'layout',
  };

  static String fingerprint(Map<String, dynamic> snapshot) {
    final safe = <String, dynamic>{for (final key in _keys) key: snapshot[key]};
    // These lists are sets in the public renderer: a storage/order change is
    // not an unpublished visual change.
    for (final key in ['equippedDecorationIds', 'flowerKinds']) {
      safe[key] =
          (safe[key] is List ? safe[key] as List : const [])
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
    }
    safe['memoryTreeStage'] ??= 0;
    safe['hasCheerFlowers'] ??= false;
    return jsonEncode(_canonical(safe));
  }

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.whereType<String>().toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
    // Firestore/JSON can return 1 where the client serialized 1.0.
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return value;
  }
}
