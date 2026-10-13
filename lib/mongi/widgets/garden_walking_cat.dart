import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/garden_life.dart';

/// Whole, uncut character frames. Tight source bounds exclude neighbouring
/// tails; measured paw baselines align every pose to the same ground point.
class GardenWalkingCat extends StatelessWidget {
  final int frame;
  final GardenCatFacing facing;
  final bool faceLeft;
  const GardenWalkingCat({super.key, required this.frame,
    required this.facing, required this.faceLeft});
  static const asset = 'assets/living_garden/cat_walk_directional.png';
  static Future<ui.Image>? _image;
  static Future<ui.Image> _load() async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List(
      bytes.offsetInBytes, bytes.lengthInBytes));
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return image;
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: _image ??= _load(),
    builder: (context, snapshot) => snapshot.hasData
      ? CustomPaint(painter: GardenWalkPainter(snapshot.data!, frame, facing, faceLeft))
      : const SizedBox.expand(),
  );
}

class GardenWalkPainter extends CustomPainter {
  final ui.Image image;
  final int frame;
  final GardenCatFacing facing;
  final bool faceLeft;
  const GardenWalkPainter(this.image, this.frame, this.facing, this.faceLeft);
  static const bounds = <Rect>[
    Rect.fromLTRB(20, 37, 232, 248),
    Rect.fromLTRB(274, 45, 489, 247),
    Rect.fromLTRB(527, 48, 744, 248),
    Rect.fromLTRB(787, 46, 1000, 247),
    Rect.fromLTRB(24, 299, 235, 504),
    Rect.fromLTRB(274, 296, 489, 504),
    Rect.fromLTRB(528, 297, 744, 504),
    Rect.fromLTRB(787, 295, 1000, 503),
    Rect.fromLTRB(58, 525, 200, 765),
    Rect.fromLTRB(314, 526, 456, 765),
    Rect.fromLTRB(569, 525, 712, 765),
    Rect.fromLTRB(825, 525, 967, 766),
    Rect.fromLTRB(58, 779, 200, 1019),
    Rect.fromLTRB(314, 778, 456, 1020),
    Rect.fromLTRB(569, 779, 712, 1020),
    Rect.fromLTRB(825, 778, 968, 1018),
    Rect.fromLTRB(61, 1038, 201, 1260),
    Rect.fromLTRB(311, 1032, 453, 1260),
    Rect.fromLTRB(573, 1034, 716, 1259),
    Rect.fromLTRB(825, 1052, 966, 1260),
    Rect.fromLTRB(61, 1270, 202, 1502),
    Rect.fromLTRB(315, 1271, 455, 1502),
    Rect.fromLTRB(568, 1275, 710, 1502),
    Rect.fromLTRB(824, 1271, 962, 1503),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final index = facing.index * 8 + frame % 8;
    final body = bounds[index];
    final source = body.inflate(2);
    final scale = size.height / 235;
    final width = source.width * scale, height = source.height * scale;
    final target = Rect.fromLTWH((size.width - width) / 2,
      size.height - height + 2 * scale, width, height);
    canvas.save();
    if (facing == GardenCatFacing.side && faceLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(image, source, target,
      Paint()..filterQuality = FilterQuality.medium);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant GardenWalkPainter old) =>
      image != old.image || frame != old.frame || facing != old.facing || faceLeft != old.faceLeft;
}
