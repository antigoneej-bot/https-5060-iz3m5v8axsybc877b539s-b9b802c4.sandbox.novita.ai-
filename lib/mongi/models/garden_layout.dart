import '../../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'seed.dart';
import 'garden_decoration.dart';

/// Coordinates are normalized to the whole garden, independent of screen size.
class GardenLayout {
  final int spaces;
  final Map<String, Offset> positions;
  GardenLayout({this.spaces = 1, Map<String, Offset> positions = const {}})
    : positions = Map.unmodifiable(positions);
  static List<String> get itemIds => [
    ...SeedType.all.map((s) => 'seed:${s.id}'),
    ...GardenDecoration.all.map((d) => 'decor:${d.id}'),
  ];
  static Offset defaultPosition(String id) {
    const added = <String, Offset>{
      'decor:daisy_pot': Offset(0.45, 0.52),
      'decor:tulip_pot': Offset(0.5, 0.52),
      'decor:sunflower_pot': Offset(0.55, 0.52),
      'decor:cat_cushion': Offset(0.44, 0.59),
      'decor:cat_basket': Offset(.437, .845),
      'decor:spring_wreath': Offset(.14, .58),
      'decor:summer_parasol': Offset(.21, .58),
      'decor:autumn_leaf_pile': Offset(.14, .72),
      'decor:winter_snowman': Offset(.21, .72),
      'decor:moon_lamp': Offset(0.5, 0.59),
      'decor:bird_house': Offset(0.56, 0.59),
    };
    if (added.containsKey(id)) return added[id]!;

    final index = itemIds.indexOf(id);
    if (index < 0) throw ArgumentError.value(id);
    // Keep the companion's home (x=.5, y=395/800) visible behind mature crowns.
    if (index == 0) return const Offset(.36, .55);
    if (index == 1) return const Offset(.64, .55);
    if (index == 2) return const Offset(.36, .88);
    final rowIndex = index - 3;
    final start = rowIndex >= 12 ? .49 : .36;
    return Offset(start + rowIndex % 6 * .056, .665 + rowIndex ~/ 6 * .11);
  }

  static double depthAt(double y) => (.88 + (y - .52) * .55).clamp(.84, 1.10);
  static double matureWidth(String id, double y) {
    final base = id.startsWith('seed:')
        ? SeedType.byId(id.substring(5)).worldArtSize(10)
        : id == 'decor:bench'
        ? 220.0
        : 104.0;
    return base * depthAt(y);
  }

  /// Render old edge placements safely without rewriting their saved coordinates.
  /// Reserve mature width from the first sprout so roots do not drift as it grows.
  static Offset visiblePosition(String id, Offset p) {
    final margin = (matureWidth(id, p.dy) / 2 + 16) / 2400;
    return Offset(p.dx.clamp(margin, 1 - margin), p.dy);
  }

  Offset position(String id) =>
      visiblePosition(id, positions[id] ?? defaultPosition(id));
  static double _groundHalfWidth(String id) =>
      id.startsWith('seed:') && SeedType.byId(id.substring(5)).isTree
      ? 130
      : id == 'decor:bench'
      ? 80
      : 42;
  static int spaceFor(double x) => x < 1 / 3 ? 0 : (x > 2 / 3 ? 2 : 1);
  bool isOpen(int zone) =>
      zone == 1 || (zone == 0 && spaces >= 2) || spaces >= 3;
  GardenLayout grow(int plantings) => GardenLayout(
    spaces: spaces > earnedSpaces(plantings) ? spaces : earnedSpaces(plantings),
    positions: positions,
  );
  static int earnedSpaces(int count) => count >= 8 ? 3 : (count >= 3 ? 2 : 1);

  /// Existing growth milestones; opening land never consumes seeds or resets care.
  static int goalForZone(int zone) => switch (zone) {
    1 => 0,
    0 => 3,
    2 => 8,
    _ => throw ArgumentError.value(zone, 'zone'),
  };
  static String nameForZone(int zone) => switch (zone) {
    1 => tr('작은 정원'),
    0 => tr('꽃밭'),
    2 => tr('나무 뜰'),
    _ => throw ArgumentError.value(zone, 'zone'),
  };
  int? get nextZone => !isOpen(0)
      ? 0
      : !isOpen(2)
      ? 2
      : null;
  int remainingGrowth(int count) =>
      nextZone == null ? 0 : (goalForZone(nextZone!) - count).clamp(0, 8);
  static bool onGround(Offset p) =>
      p.dx.isFinite &&
      p.dy.isFinite &&
      p.dx >= .035 &&
      p.dx <= .965 &&
      p.dy >= .52 &&
      p.dy <= .91;

  /// The new background's pond is above the plantable lawn. This bound only
  /// provides a specific message; saved placement validation is unchanged.
  static const pondBounds = Rect.fromLTRB(.07, .30, .25, .49);

  /// Sparse hints, not mandatory slots. Use the SAME validator as plantAt/move.
  /// Arbitrary valid lawn positions remain available between these hints.
  List<Offset> plantingHints(String id, Iterable<String> visible) {
    final occupied = visible.toList(growable: false);
    return [
      for (var row = 0; row < 5; row++)
        for (var col = 0; col < 16; col++)
          if (placementError(
                id,
                Offset((120 + col * 144) / 2400, (438 + row * 66) / 800),
                occupied,
              ) ==
              null)
            Offset((120 + col * 144) / 2400, (438 + row * 66) / 800),
    ];
  }

  String? placementError(String id, Offset p, Iterable<String> visible) {
    if (!itemIds.contains(id)) return tr('알 수 없는 아이템이에요.');
    if (pondBounds.contains(p)) return tr('연못에는 심을 수 없어요. 잔디를 골라 주세요.');
    if (!onGround(p) || visiblePosition(id, p) != p)
      return tr('다 자랄 공간이 있도록 잔디 안쪽을 골라 주세요.');
    if (!isOpen(spaceFor(p.dx))) return tr('아직 열리지 않은 공간이에요.');
    for (final other in visible) {
      if (other == id) continue;
      final delta = p - position(other);
      // Keep ground targets accessible while allowing natural canopy overlap
      // between different depth rows.
      if ((delta.dx * 2400).abs() <
              _groundHalfWidth(id) + _groundHalfWidth(other) + 12 &&
          (delta.dy * 800).abs() < 52) {
        return tr('다른 아이템과 조금 떨어뜨려 주세요.');
      }
    }
    return null;
  }

  GardenLayout move(String id, Offset p, Iterable<String> visible) {
    if (!visible.contains(id)) throw StateError('정원에 있는 아이템만 옮길 수 있어요.');
    final error = placementError(id, p, visible);
    if (error != null) throw StateError(error);
    return GardenLayout(spaces: spaces, positions: {...positions, id: p});
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'spaces': spaces,
    'positions': positions.map((k, v) => MapEntry(k, [v.dx, v.dy])),
  };
  factory GardenLayout.fromJson(Map<dynamic, dynamic> json) {
    final spaces = json['spaces'];
    final raw = json['positions'];
    if (json['version'] != 1 ||
        spaces is! int ||
        spaces < 1 ||
        spaces > 3 ||
        raw is! Map ||
        raw.length > itemIds.length) {
      throw const FormatException('잘못된 정원 배치 기록');
    }
    final positions = <String, Offset>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (!itemIds.contains(e.key) ||
          v is! List ||
          v.length != 2 ||
          v[0] is! num ||
          v[1] is! num) {
        throw const FormatException('잘못된 정원 좌표');
      }
      final p = Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
      if (!onGround(p) ||
          !(GardenLayout(spaces: spaces).isOpen(spaceFor(p.dx)))) {
        throw const FormatException('정원 범위를 벗어난 배치');
      }
      positions[e.key as String] = p;
    }
    return GardenLayout(spaces: spaces, positions: positions);
  }
}
