import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/garden_gifts.dart';
import 'garden_gift_art.dart';

const gardenResponseLabels = {
  'heart': '몽이가 하트를 앞발로 톡 건드려요',
  'star': '몽이가 반짝이는 별을 올려다봐요',
  'hug': '몽이가 따뜻한 마음을 꼭 안아요',
  'butterfly': '몽이가 나비를 바라봐요',
};

class GardenCatResponse extends StatelessWidget {
  final String kind;
  final double progress;
  final bool animated;
  const GardenCatResponse({
    super.key,
    required this.kind,
    required this.progress,
    required this.animated,
  });
  @override
  Widget build(BuildContext context) {
    final index = gardenReactionNames.keys.toList().indexOf(kind).clamp(0, 3);
    final wave = animated ? math.sin(progress * math.pi) : 0.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.rotate(
            angle: kind == 'heart' ? -.025 * wave : .012 * wave,
            alignment: Alignment.bottomCenter,
            child: GardenAtlasArt(
              asset: 'assets/living_garden/cat_reactions.webp',
              column: index % 2,
              row: index ~/ 2,
              columns: 2,
            ),
          ),
        ),
        Positioned(
          top: -12 - wave * 8,
          right: kind == 'star' ? 35 : 0,
          child: Transform.scale(
            scale: 1 + wave * .1,
            child: Text(
              gardenReactionEmoji[kind] ?? '💗',
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
      ],
    );
  }
}
