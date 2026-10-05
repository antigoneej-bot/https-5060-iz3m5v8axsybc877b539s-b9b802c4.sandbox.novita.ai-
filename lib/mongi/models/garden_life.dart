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

class GardenCatMoment {
  final Offset feet;
  final bool resting, walking, faceLeft;
  final int frame;
  final double tilt, size;
  final String label;
  const GardenCatMoment(
    this.feet,
    this.resting,
    this.tilt,
    this.size,
    this.label, {
    this.walking = false,
    this.faceLeft = false,
    this.frame = 0,
  });
  static GardenCatMoment at(
    double seconds, {
    Offset? plant,
    Offset? bench,
    bool quiet = false,
    bool animated = true,
  }) {
    const home = Offset(1200, 395);
    Offset safe(Offset p) =>
        Offset(p.dx.clamp(95.0, 2305.0), p.dy.clamp(350.0, 740.0));
    final sniff = safe(
      plant == null ? const Offset(1310, 425) : plant + const Offset(-66, -5),
    );
    final seat = safe(
      bench == null ? const Offset(1150, 410) : bench + const Offset(0, -58),
    );
    final ground = bench == null ? seat : seat + const Offset(-60, 58);
    final restSize = bench == null ? 145.0 : 105.0;
    if (quiet) {
      return GardenCatMoment(seat, true, 0, restSize, '몽이가 곁에서 쉬고 있어요');
    }
    if (!animated) return const GardenCatMoment(home, false, 0, 152, '몽이');
    double duration(Offset a, Offset b) => (b - a).distance / 48 + 1;
    final a = duration(home, sniff),
        b = duration(sniff, ground),
        c = duration(ground, home);
    var t = seconds % (4 + a + 5 + b + 1 + 9 + 1 + c);
    GardenCatMoment walk(Offset from, Offset to, double t, double length) {
      final p = (t / length).clamp(0.0, 1.0);
      // Smooth acceleration/deceleration, with distance determining travel time.
      final eased = p * p * (3 - 2 * p);
      final gait = t * 6;
      final bob = math.sin(gait * math.pi).abs() * 2;
      return GardenCatMoment(
        Offset.lerp(from, to, eased)! - Offset(0, bob),
        false,
        0,
        145,
        '천천히 걷는 몽이',
        walking: true,
        faceLeft: to.dx < from.dx,
        frame: gait.floor() % 4,
      );
    }

    if (t < 4) return const GardenCatMoment(home, false, 0, 152, '나비를 바라보는 몽이');
    t -= 4;
    if (t < a) return walk(home, sniff, t, a);
    t -= a;
    if (t < 5) {
      return GardenCatMoment(
        sniff,
        false,
        math.sin(t * math.pi / 5) * .07,
        145,
        '꽃향기를 맡는 몽이',
      );
    }
    t -= 5;
    if (t < b) return walk(sniff, ground, t, b);
    t -= b;
    GardenCatMoment hop(
      Offset from,
      Offset to,
      double p,
      double fromSize,
      double toSize,
    ) => GardenCatMoment(
      Offset.lerp(from, to, p)! - Offset(0, math.sin(p * math.pi) * 26),
      false,
      -.04 * math.sin(p * math.pi),
      fromSize + (toSize - fromSize) * p,
      '벤치에 오르는 몽이',
      walking: true,
      frame: 2,
    );
    if (t < 1) return hop(ground, seat, t, 145, restSize);
    t -= 1;
    if (t < 9) return GardenCatMoment(seat, true, 0, restSize, '잠깐 졸고 있는 몽이');
    t -= 9;
    if (t < 1) return hop(seat, ground, t, restSize, 145);
    t -= 1;
    return walk(ground, home, t, c);
  }
}
