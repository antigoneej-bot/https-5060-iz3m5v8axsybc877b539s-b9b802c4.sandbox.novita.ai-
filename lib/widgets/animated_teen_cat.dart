import 'package:flutter/material.dart';
import 'growth_cat_motion.dart';

/// Quiet idle motion plus reactions to the existing care-screen tap handler.
class AnimatedTeenCat extends StatelessWidget {
  final double size;
  final int reactionToken;
  const AnimatedTeenCat({super.key, this.size = 132, this.reactionToken = 0});
  @override
  Widget build(BuildContext context) => GrowthCatMotion(
    asset: 'assets/growth/teen_frames/teen_01.png', size: size, reactionToken: reactionToken,
  );
}
