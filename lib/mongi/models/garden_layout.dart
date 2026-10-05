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
    final index = itemIds.indexOf(id);
    if (index < 0) throw ArgumentError.value(id);
    return Offset(.42 + index % 5 * .04, .55 + index ~/ 5 * .105);
  }

  Offset position(String id) => positions[id] ?? defaultPosition(id);
  static int spaceFor(double x) => x < 1 / 3 ? 0 : (x > 2 / 3 ? 2 : 1);
  bool isOpen(int zone) =>
      zone == 1 || (zone == 0 && spaces >= 2) || spaces >= 3;
  GardenLayout grow(int plantings) => GardenLayout(
    spaces: spaces > earnedSpaces(plantings) ? spaces : earnedSpaces(plantings),
    positions: positions,
  );
  static int earnedSpaces(int count) => count >= 8 ? 3 : (count >= 3 ? 2 : 1);
  static bool onGround(Offset p) =>
      p.dx.isFinite &&
      p.dy.isFinite &&
      p.dx >= .035 &&
      p.dx <= .965 &&
      p.dy >= .52 &&
      p.dy <= .91;
  String? placementError(String id, Offset p, Iterable<String> visible) {
    if (!itemIds.contains(id)) return '알 수 없는 아이템이에요.';
    if (!onGround(p)) return '잔디 안쪽을 골라 주세요.';
    if (!isOpen(spaceFor(p.dx))) return '아직 열리지 않은 공간이에요.';
    for (final other in visible) {
      if (other == id) continue;
      final delta = p - position(other);
      if (Offset(delta.dx * 2400, delta.dy * 800).distance < 80) {
        return '다른 아이템과 조금 떨어뜨려 주세요.';
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
