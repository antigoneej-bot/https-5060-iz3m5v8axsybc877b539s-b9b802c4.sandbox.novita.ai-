import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/letter_entry.dart';

/// Counts writing days, regardless of the emotion or the number of retries.
List<DateTime> gardenMemoryDays(Iterable<LetterEntry> letters) {
  final days = <DateTime>{};
  for (final letter in letters) {
    final d = letter.date.toLocal();
    days.add(DateTime(d.year, d.month, d.day));
  }
  return days.toList()..sort((a, b) => b.compareTo(a));
}

/// One destination on Mongi's garden tour: a ground point plus how long to
/// linger there and what to say while resting.
class _Stop {
  final Offset to;
  final double rest;
  final String arriveLabel, walkLabel;
  const _Stop(this.to, this.rest, this.arriveLabel, {this.walkLabel = '천천히 걷는 몽이'});
}

class GardenCatMoment {
  final Offset feet;
  final bool resting, walking, faceLeft;
  final int frame;
  final double tilt, size;
  final String label;

  /// Pure ground-contact height, separate from [feet]. Only differs from
  /// `feet.dy` during the bench hop's vertical arc, so a drawn shadow can
  /// stay flat on the lawn instead of floating up and down with the body.
  final double? groundDy;
  const GardenCatMoment(
    this.feet,
    this.resting,
    this.tilt,
    this.size,
    this.label, {
    this.walking = false,
    this.faceLeft = false,
    this.frame = 0,
    this.groundDy,
  });
  double get contactDy => groundDy ?? feet.dy;

  /// The cat sits a little smaller toward the back of the lawn and a little
  /// larger near the front - smooth and identical for day and night, since
  /// this never looks at the time of day, only the ground position.
  static double depthSize(double feetDy) {
    final norm = (feetDy / 800).clamp(.50, .92);
    final depth = (.82 + (norm - .52) * .82).clamp(.78, 1.16);
    return 148.0 * depth;
  }

  /// A short detour around anything standing between [a] and [b], so the
  /// walk never clips through a tree, the bench or a planted item. Only the
  /// single worst offender is avoided - with sparse garden decorations one
  /// bend is enough, and it keeps the path gentle instead of jagged.
  static List<Offset> _path(Offset a, Offset b, List<Offset> obstacles) {
    const radius = 74.0;
    final ab = b - a;
    final len2 = ab.distanceSquared;
    if (len2 < 1) return [a, b];
    Offset? bend;
    var worst = 0.0;
    for (final o in obstacles) {
      final t = (((o.dx - a.dx) * ab.dx + (o.dy - a.dy) * ab.dy) / len2).clamp(
        0.0,
        1.0,
      );
      if (t < .08 || t > .92) continue; // ignore the stop itself
      final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
      final dist = (o - closest).distance;
      if (dist < radius) {
        final penetration = radius - dist;
        if (penetration > worst) {
          worst = penetration;
          final along = ab.distance;
          final normal = along == 0
              ? const Offset(0, 1)
              : Offset(-ab.dy / along, ab.dx / along);
          final side =
              ((o.dx - closest.dx) * normal.dx + (o.dy - closest.dy) * normal.dy) >= 0
              ? -1.0
              : 1.0;
          bend = closest + normal * (side * (radius + 20));
        }
      }
    }
    return bend == null ? [a, b] : [a, bend, b];
  }

  static double _pathLength(List<Offset> path) {
    var total = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      total += (path[i + 1] - path[i]).distance;
    }
    return total;
  }

  /// Walking seconds scale with real distance, so a far destination simply
  /// takes longer rather than teleporting a fast-moving body.
  static double _legSeconds(Offset a, Offset b, List<Offset> obstacles) =>
      _pathLength(_path(a, b, obstacles)) / 66 + .5;

  /// Moves along the (possibly bent) path by eased arc length, so the paws
  /// advance by exactly as much ground as the body actually covers - no
  /// more "feet sliding while the body glides" moonwalk effect.
  static ({Offset pos, double traveled, bool faceLeft}) _advance(
    List<Offset> path,
    double easedFraction,
  ) {
    final total = _pathLength(path);
    var target = (easedFraction * total).clamp(0.0, total);
    final overallFaceLeft = path.last.dx < path.first.dx;
    for (var i = 0; i < path.length - 1; i++) {
      final segLen = (path[i + 1] - path[i]).distance;
      final isLast = i == path.length - 2;
      if (target <= segLen || isLast) {
        final segP = segLen == 0 ? 0.0 : (target / segLen).clamp(0.0, 1.0);
        final pos = Offset.lerp(path[i], path[i + 1], segP)!;
        return (
          pos: pos,
          traveled: easedFraction * total,
          faceLeft: path[i + 1].dx == path[i].dx
              ? overallFaceLeft
              : path[i + 1].dx < path[i].dx,
        );
      }
      target -= segLen;
    }
    return (pos: path.last, traveled: total, faceLeft: overallFaceLeft);
  }

  static GardenCatMoment _walking(
    Offset from,
    Offset to,
    List<Offset> obstacles,
    double t,
    double duration,
    String label,
  ) {
    final path = _path(from, to, obstacles);
    final p = duration <= 0 ? 1.0 : (t / duration).clamp(0.0, 1.0);
    // Smooth acceleration/deceleration; distance (not a fixed clock) sets pace.
    final eased = p * p * (3 - 2 * p);
    final step = _advance(path, eased);
    const stride = 34.0; // ground distance per walk-cycle frame
    final frame = (step.traveled / stride).floor() % 4;
    return GardenCatMoment(
      step.pos,
      false,
      0,
      depthSize(step.pos.dy),
      label,
      walking: true,
      faceLeft: step.faceLeft,
      frame: frame,
    );
  }

  static GardenCatMoment _hop(
    Offset from,
    Offset to,
    double p,
    double fromSize,
    double toSize,
    String label,
  ) {
    final ground = Offset.lerp(from, to, p)!;
    return GardenCatMoment(
      ground - Offset(0, math.sin(p * math.pi) * 22),
      false,
      -.04 * math.sin(p * math.pi),
      fromSize + (toSize - fromSize) * p,
      label,
      walking: true,
      frame: 2,
      groundDy: ground.dy,
    );
  }

  static GardenCatMoment at(
    double seconds, {
    Offset? plant,
    Offset? bench,
    List<Offset> obstacles = const [],
    bool zoneLeftOpen = false,
    bool zoneRightOpen = false,
    bool quiet = false,
    bool animated = true,
    Offset? anchor,
  }) {
    Offset safe(Offset p) =>
        Offset(p.dx.clamp(110.0, 2290.0), p.dy.clamp(420.0, 720.0));
    const home = Offset(1200, 395);
    final sniff = plant == null
        ? null
        : safe(plant + const Offset(-66, -5));
    final seat = bench == null ? null : safe(bench + const Offset(0, -58));
    final ground = seat == null ? null : safe(seat + const Offset(-60, 58));
    final flowerBed = zoneLeftOpen ? const Offset(560, 525) : null;
    final treeYard = zoneRightOpen ? const Offset(1840, 505) : null;
    const frontLawn = Offset(1000, 645);

    if (quiet) {
      final pos = seat ?? anchor ?? home;
      return GardenCatMoment(
        pos,
        true,
        0,
        seat != null ? depthSize(pos.dy) * .73 : depthSize(pos.dy),
        '몽이가 곁에서 쉬고 있어요',
      );
    }
    if (!animated) {
      // Settle exactly where it last stood - never snap back to a start point.
      final pos = anchor ?? home;
      return GardenCatMoment(pos, true, 0, depthSize(pos.dy), '몽이');
    }

    // The open-air tour: home -> flower bed -> a favourite plant -> the
    // front lawn -> the tree yard -> (if there's a bench) a nap -> home.
    // Locked zones and missing items simply drop out of the list below.
    final stops = <_Stop>[];
    void addStop(Offset to, double rest, String arriveLabel, {String? walkLabel}) {
      stops.add(
        _Stop(
          to,
          rest,
          arriveLabel,
          walkLabel: walkLabel ?? '천천히 걷는 몽이',
        ),
      );
    }

    if (flowerBed != null) addStop(flowerBed, 4, '꽃밭을 구경하는 몽이');
    if (sniff != null) addStop(sniff, 5, '꽃향기를 맡는 몽이');
    addStop(frontLawn, 3, '앞마당을 거니는 몽이');
    if (treeYard != null) addStop(treeYard, 4, '나무 그늘을 즐기는 몽이');
    if (ground != null) {
      addStop(ground, 0, '', walkLabel: '벤치로 가는 몽이');
    }
    addStop(home, 3, '마당을 바라보는 몽이');

    const benchHop = 1.0, benchRest = 9.0, benchHopBack = 1.0;
    var from = home; // the tour always starts and loops back from home
    final legs = <({Offset from, Offset to, double walk, _Stop stop})>[];
    for (final stop in stops) {
      legs.add((
        from: from,
        to: stop.to,
        walk: _legSeconds(from, stop.to, obstacles),
        stop: stop,
      ));
      from = stop.to;
    }

    var total = 0.0;
    for (final leg in legs) {
      total += leg.walk;
      total += (leg.to == ground) ? benchHop + benchRest + benchHopBack : leg.stop.rest;
    }
    var t = total <= 0 ? 0.0 : seconds % total;

    for (final leg in legs) {
      if (t < leg.walk) {
        return _walking(leg.from, leg.to, obstacles, t, leg.walk, leg.stop.walkLabel);
      }
      t -= leg.walk;
      if (leg.to == ground) {
        if (t < benchHop) {
          return _hop(
            ground!,
            seat!,
            t / benchHop,
            depthSize(ground.dy),
            depthSize(seat.dy) * .73,
            '벤치에 오르는 몽이',
          );
        }
        t -= benchHop;
        if (t < benchRest) {
          return GardenCatMoment(
            seat!,
            true,
            0,
            depthSize(seat.dy) * .73,
            '잠깐 졸고 있는 몽이',
          );
        }
        t -= benchRest;
        if (t < benchHopBack) {
          return _hop(
            seat!,
            ground!,
            t / benchHopBack,
            depthSize(seat.dy) * .73,
            depthSize(ground.dy),
            '벤치에서 내려오는 몽이',
          );
        }
        t -= benchHopBack;
      } else if (leg.stop.rest > 0) {
        if (t < leg.stop.rest) {
          final tilt =
              math.sin((t / leg.stop.rest).clamp(0.0, 1.0) * math.pi) * .05;
          return GardenCatMoment(
            leg.to,
            false,
            tilt,
            depthSize(leg.to.dy),
            leg.stop.arriveLabel,
          );
        }
        t -= leg.stop.rest;
      }
    }
    return GardenCatMoment(home, false, 0, depthSize(home.dy), '몽이');
  }
}
