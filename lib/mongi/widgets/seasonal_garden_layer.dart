import 'package:flutter/material.dart';
import '../../services/garden_style_store.dart';
class SeasonalGardenLayer extends StatelessWidget {
  const SeasonalGardenLayer({super.key});
  @override
  Widget build(BuildContext context) => IgnorePointer(child: AnimatedBuilder(
    animation: GardenStyleStore.instance, builder: (_, __) => CustomPaint(
      painter: _SeasonPainter(GardenStyleStore.instance.season), size: Size.infinite)));
}
class _SeasonPainter extends CustomPainter {
  const _SeasonPainter(this.season);
  final String season;
  @override
  void paint(Canvas canvas, Size size) {
    if (season == 'original') return;
    final color = switch (season) {'spring' => const Color(0x99EBA9BE), 'summer' => const Color(0x6683AD71),
      'autumn' => const Color(0xBBDDAD62), _ => const Color(0xDDEDF6FA)};
    final p = Paint()..color = color;
    // Ground decorations use world coordinates, so panning does not move them relative to plants.
    for (var i = 0; i < 52; i++) {
      final x = (i * 173 % 2380).toDouble() + 10;
      final y = 520.0 + (i * 47 % 245);
      if (season == 'winter') { canvas.drawCircle(Offset(x, y), (2 + i % 4).toDouble(), p); }
      else { canvas.save(); canvas.translate(x, y); canvas.rotate(i * .71);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: (7 + i % 5).toDouble(), height: 4), p); canvas.restore(); }
    }
  }
  @override
  bool shouldRepaint(_SeasonPainter old) => old.season != season;
}
