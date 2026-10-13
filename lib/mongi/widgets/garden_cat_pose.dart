import 'package:flutter/material.dart';

/// Source-image measurements. All poses share the bottom of the parent as
/// their physical foot position; transparent padding is not ground geometry.
class GardenCatPose extends StatelessWidget {
  final Widget child;
  final bool walking;
  final int frame;
  final String? reaction;
  const GardenCatPose({
    super.key,
    required this.child,
    this.walking = false,
    this.frame = 0,
    this.reaction,
  });

  static double footFraction({bool walking = false, int frame = 0,
      String? reaction}) {
    if (reaction != null) {
      return switch (reaction) {
        'heart' || 'star' => 495 / 500,
        'hug' => 461 / 500,
        'butterfly' => 469 / 500,
        _ => 1213 / 1254,
      };
    }
    return walking ? 1.0
        : 1213 / 1254;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
    // The walking painter already aligns whole-frame paws with this baseline.
    if (walking) return SizedBox.expand(child: child);
    final h = box.maxHeight;
    final w = box.maxWidth;
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: (box.maxWidth - w) / 2,
        top: box.maxHeight - h * footFraction(
          walking: walking, frame: frame, reaction: reaction),
        width: w,
        height: h,
        child: child,
      ),
    ]);
  });
}
