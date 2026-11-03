import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Calendar-only subject framing. Source cards and record IDs stay untouched.
/// Cards contain opaque paper margins, so alpha-based trimming cannot find them.
class EmotionCatThumbnail extends StatelessWidget {
  const EmotionCatThumbnail({
    super.key,
    required this.asset,
    required this.label,
  });
  final String asset, label;

  // Normalized subject bounds, with breathing room around ears and expressions.
  static const subjects = <String, Rect>{
    'cat_02.png': Rect.fromLTRB(0.20, 0.22, 0.89, 0.88),
    'cat_03.png': Rect.fromLTRB(0.03, 0.14, 1.00, 0.99),
    'cat_04.png': Rect.fromLTRB(0.20, 0.06, 0.85, 0.94),
    'cat_05.png': Rect.fromLTRB(0.23, 0.15, 0.87, 0.92),
    'cat_06.png': Rect.fromLTRB(0.29, 0.20, 0.88, 0.93),
    'cat_07.png': Rect.fromLTRB(0.11, 0.27, 0.93, 0.89),
    'cat_08.png': Rect.fromLTRB(0.22, 0.06, 0.91, 0.96),
    'cat_09.png': Rect.fromLTRB(0.17, 0.35, 0.87, 0.90),
    'cat_10.png': Rect.fromLTRB(0.20, 0.23, 0.84, 0.89),
    'cat_11.png': Rect.fromLTRB(0.19, 0.16, 0.91, 0.97),
    'cat_12.png': Rect.fromLTRB(0.18, 0.23, 0.85, 0.89),
    'cat_13.png': Rect.fromLTRB(0.27, 0.26, 0.85, 0.96),
    'cat_14.png': Rect.fromLTRB(0.23, 0.13, 0.87, 0.95),
    'cat_15.png': Rect.fromLTRB(0.42, 0.43, 0.96, 1.00),
    'cat_18.png': Rect.fromLTRB(0.05, 0.24, 0.96, 0.97),
    'cat_19.png': Rect.fromLTRB(0.09, 0.39, 0.96, 0.93),
    'cat_20.png': Rect.fromLTRB(0.15, 0.30, 0.70, 0.94),
    'cat_22.png': Rect.fromLTRB(0.26, 0.43, 0.85, 0.97),
    'cat_23.png': Rect.fromLTRB(0.23, 0.14, 0.87, 0.99),
    'cat_24.png': Rect.fromLTRB(0.26, 0.32, 0.77, 0.89),
    'cat_25.png': Rect.fromLTRB(0.12, 0.21, 0.97, 0.99),
    'cat_26.png': Rect.fromLTRB(0.07, 0.25, 0.99, 0.99),
    'cat_27.png': Rect.fromLTRB(0.26, 0.16, 0.89, 0.96),
    'cat_28.png': Rect.fromLTRB(0.17, 0.20, 0.86, 0.89),
    'cat_29.png': Rect.fromLTRB(0.26, 0.27, 0.84, 0.99),
    'cat_32.png': Rect.fromLTRB(0.25, 0.42, 0.85, 0.97),
    'cat_33.png': Rect.fromLTRB(0.28, 0.35, 0.85, 0.96),
    'cat_36.png': Rect.fromLTRB(0.15, 0.34, 0.91, 1.00),
    'cat_37.png': Rect.fromLTRB(0.02, 0.20, 0.97, 0.96),
    'cat_38.png': Rect.fromLTRB(0.19, 0.11, 0.85, 1.00),
    'cat_39.png': Rect.fromLTRB(0.07, 0.37, 0.95, 0.89),
    'cat_40.png': Rect.fromLTRB(0.20, 0.15, 0.95, 1.00),
    'cat_43.png': Rect.fromLTRB(0.22, 0.22, 0.88, 0.99),
    'cat_45.png': Rect.fromLTRB(0.26, 0.17, 0.85, 0.98),
    'cat_46.png': Rect.fromLTRB(0.21, 0.25, 0.82, 0.96),
    'cat_47.png': Rect.fromLTRB(0.05, 0.19, 1.00, 0.95),
    'cat_48.png': Rect.fromLTRB(0.19, 0.14, 0.88, 0.98),
  };

  @override
  Widget build(BuildContext context) {
    final subject =
        subjects[asset.split('/').last] ?? const Rect.fromLTWH(0, 0, 1, 1);
    return Semantics(
      label: '$label 고양이',
      image: true,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final scale = math.min(
              box.maxWidth / subject.width,
              box.maxHeight / subject.height,
            );
            return Stack(
              children: [
                Positioned(
                  left:
                      (box.maxWidth - subject.width * scale) / 2 -
                      subject.left * scale,
                  top:
                      (box.maxHeight - subject.height * scale) / 2 -
                      subject.top * scale,
                  width: scale,
                  height: scale,
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    cacheWidth: 384,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
