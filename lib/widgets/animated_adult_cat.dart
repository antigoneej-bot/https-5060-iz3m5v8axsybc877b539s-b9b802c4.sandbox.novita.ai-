import 'package:flutter/material.dart';
import 'growth_cat_motion.dart';

/// Graduation outfit retained; reactions are more restrained than the teen cat.
class AnimatedAdultCat extends StatelessWidget {
  final double size;
  final int reactionToken;
  const AnimatedAdultCat({super.key, this.size = 132, this.reactionToken = 0});
  @override
  Widget build(BuildContext context) => GrowthCatMotion(
    asset: 'assets/growth/adult_frames/adult_01.png', size: size,
    adult: true, reactionToken: reactionToken,
  );
}
