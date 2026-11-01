import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/companion_motion.dart';
import 'companion_motion_art.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/companion_coat.dart';
import '../providers/cat_care_provider.dart';

/// A visited garden must never display the visitor's personal cat preference.
class CompanionCoatScope extends InheritedWidget {
  final bool useLocalChoice;
  final CompanionCoat? coat;
  final int? growthStage;
  const CompanionCoatScope({
    super.key,
    required this.useLocalChoice,
    this.coat,
    this.growthStage,
    required super.child,
  });
  @override
  bool updateShouldNotify(CompanionCoatScope oldWidget) =>
      useLocalChoice != oldWidget.useLocalChoice ||
      coat != oldWidget.coat ||
      growthStage != oldWidget.growthStage;
}

CompanionCoat? selectedCompanionCoat(BuildContext context) {
  if (context
          .dependOnInheritedWidgetOfExactType<CompanionCoatScope>()
          ?.useLocalChoice ==
      false)
    return null;
  return context
          .dependOnInheritedWidgetOfExactType<CompanionCoatScope>()
          ?.coat ??
      (context.watch<CatCareProvider?>() == null
          ? null
          : context.watch<CatCareProvider?>()!.journey.coat ??
                CompanionCoat.ginger);
}

class CompanionCoatArt extends StatelessWidget {
  static const asset = 'assets/living_garden/companion_coats.png';
  final CompanionCoat coat;
  final double tilt, breath;
  final CompanionMotionPose? motion;
  const CompanionCoatArt({
    super.key,
    required this.coat,
    this.motion,
    this.tilt = 0,
    this.breath = 1,
  });
  static Future<ui.Image>? _image;
  static ui.Image? _decoded;
  static Future<ui.Image> _load() async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return _decoded = frame.image;
  }

  Widget _still() => FutureBuilder<ui.Image>(
    future: _decoded != null
        ? SynchronousFuture(_decoded!)
        : (_image ??= _load()),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        _image = null;
        return const Center(child: Icon(Icons.pets, size: 48));
      }
      if (!snapshot.hasData) return const SizedBox.expand();
      return CustomPaint(
        painter: CompanionCoatPainter(snapshot.data!, coat, tilt, breath),
      );
    },
  );
  @override
  Widget build(BuildContext context) => Semantics(
    label: coat.label,
    image: true,
    child: motion == null
        ? _still()
        : CompanionMotionArt(
            coat: coat,
            pose: motion!,
            fallback: _still(),
            growthStage:
                context
                    .dependOnInheritedWidgetOfExactType<CompanionCoatScope>()
                    ?.growthStage ??
                ((context.watch<CatCareProvider?>()?.journey.keepBaby ?? false)
                    ? 0
                    : context.watch<CatCareProvider?>()?.journey.stage ?? 0),
          ),
  );
}

class CompanionCoatPainter extends CustomPainter {
  final ui.Image image;
  final CompanionCoat coat;
  final double tilt, breath;
  const CompanionCoatPainter(this.image, this.coat, this.tilt, this.breath);
  // Measured complete silhouettes, including whiskers and curled tails.
  static const bounds = <Rect>[
    Rect.fromLTRB(65, 30, 550, 512),
    Rect.fromLTRB(570, 30, 1055, 512),
    Rect.fromLTRB(1060, 30, 1536, 512),
    Rect.fromLTRB(65, 515, 555, 994),
    Rect.fromLTRB(565, 515, 1055, 994),
    Rect.fromLTRB(1060, 515, 1536, 994),
  ];
  static const paws = [505.0, 503.0, 506.0, 979.0, 980.0, 979.0];
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final source = bounds[coat.index];
    final scale = math.min(
      size.width / source.width,
      size.height / source.height,
    );
    final w = source.width * scale, h = source.height * scale;
    final foot = size.height * (1213 / 1254);
    final y = foot - (paws[coat.index] - source.top) * scale;
    final target = Rect.fromLTWH((size.width - w) / 2, y, w, h);
    canvas.save();
    canvas.translate(size.width / 2, foot);
    canvas.rotate(tilt.clamp(-.025, .025));
    canvas.scale(1, breath.clamp(.997, 1.003));
    canvas.translate(-size.width / 2, -foot);
    canvas.drawImageRect(
      image,
      source,
      target,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CompanionCoatPainter old) =>
      image != old.image ||
      coat != old.coat ||
      tilt != old.tilt ||
      breath != old.breath;
}
