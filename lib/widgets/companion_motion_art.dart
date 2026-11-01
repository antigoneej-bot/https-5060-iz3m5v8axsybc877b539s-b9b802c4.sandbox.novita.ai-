import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/companion_coat.dart';
import '../models/companion_motion.dart';

class CompanionSpriteFrame {
  final Rect source;
  final double anchorX, footY;
  const CompanionSpriteFrame(this.source, this.anchorX, this.footY);
}

class CompanionSpriteAtlas {
  final ui.Image image;
  final List<CompanionSpriteFrame> frames;
  final double idleHeight, walkHeight;
  const CompanionSpriteAtlas(
    this.image,
    this.frames,
    this.idleHeight,
    this.walkHeight,
  );
  static final _loaded = <CompanionCoat, CompanionSpriteAtlas>{};
  static final _pending = <CompanionCoat, Future<CompanionSpriteAtlas>>{};
  static Future<CompanionSpriteAtlas> load(CompanionCoat coat) {
    final cached = _loaded[coat];
    if (cached != null) return SynchronousFuture(cached);
    return _pending.putIfAbsent(coat, () => _decode(coat));
  }

  static Future<CompanionSpriteAtlas> _decode(CompanionCoat coat) async {
    try {
      final all =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/living_garden/companion_motion.json',
                ),
              )
              as Map;
      final data = all[coat.name] as Map;
      final bytes = await rootBundle.load(
        'assets/living_garden/companion_motion_${coat.name}.webp',
      );
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      final frames = (data['frames'] as List)
          .map((raw) {
            final rect = (raw['rect'] as List)
                .map((n) => (n as num).toDouble())
                .toList();
            return CompanionSpriteFrame(
              Rect.fromLTRB(rect[0], rect[1], rect[2], rect[3]),
              (raw['anchorX'] as num).toDouble(),
              (raw['footY'] as num).toDouble(),
            );
          })
          .toList(growable: false);
      return _loaded[coat] = CompanionSpriteAtlas(
        image,
        frames,
        (data['idleHeight'] as num).toDouble(),
        (data['walkHeight'] as num).toDouble(),
      );
    } finally {
      _pending.remove(coat);
    }
  }
}

class CompanionMotionArt extends StatelessWidget {
  final CompanionCoat coat;
  final CompanionMotionPose pose;
  final Widget fallback;
  final int growthStage;
  const CompanionMotionArt({
    super.key,
    required this.coat,
    required this.pose,
    required this.fallback,
    this.growthStage = 0,
  });
  @override
  Widget build(BuildContext context) => FutureBuilder<CompanionSpriteAtlas>(
    future: CompanionSpriteAtlas.load(coat),
    builder: (context, snapshot) => snapshot.hasData
        ? CustomPaint(
            painter: CompanionMotionPainter(
              snapshot.data!,
              pose,
              growthStage: growthStage,
            ),
          )
        : fallback,
  );
}

class CompanionMotionPainter extends CustomPainter {
  final CompanionSpriteAtlas atlas;
  final CompanionMotionPose pose;
  final int growthStage;
  const CompanionMotionPainter(this.atlas, this.pose, {this.growthStage = 0});
  static const baseline = 1213 / 1254;
  static Rect destination(CompanionSpriteAtlas atlas, int index, Size size) {
    final f = atlas.frames[index];
    final walking = index >= 6;
    final group = atlas.frames.sublist(walking ? 6 : 0, walking ? 12 : 6);
    // Uniform per-mode scale, not a separate resize per frame.
    final extent = group.fold<double>(
      0,
      (m, f) => math.max(
        m,
        math.max(f.anchorX - f.source.left, f.source.right - f.anchorX),
      ),
    );
    final scale = math.min(
      size.width * .48 / extent,
      size.height *
          (walking ? .72 : .87) /
          (walking ? atlas.walkHeight : atlas.idleHeight),
    );
    return Rect.fromLTWH(
      size.width / 2 - (f.anchorX - f.source.left) * scale,
      size.height * baseline - (f.footY - f.source.top) * scale,
      f.source.width * scale,
      f.source.height * scale,
    );
  }

  void _frame(Canvas canvas, Size size, int frame, double alpha) {
    if (growthStage > 0 || (frame < 6 && pose.tailSwing.abs() > .0001)) {
      _tailMesh(canvas, size, frame);
      return;
    }
    canvas.drawImageRect(
      atlas.image,
      atlas.frames[frame].source,
      destination(atlas, frame, size),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: alpha),
    );
  }

  /// The head, paws and body center remain fixed; only the outside tail area
  /// bends on the same textured surface, so no detached layers are exposed.
  static Offset tailWarp(Offset p, double anchorFraction, double swing) {
    double ease(double x) {
      final t = x.clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    final outer = ease((p.dx - anchorFraction - .20) / .18);
    final belowHead = ease((p.dy - .28) / .14);
    final aboveFeet = ease((.94 - p.dy) / .5);
    return Offset(p.dx + .05 * swing * outer * belowHead * aboveFeet, p.dy);
  }

  /// Continuous proportion change: narrower head and longer lower body.
  /// Feet remain anchored; walking frames use a gentler change.
  static Offset growthWarp(Offset p, int stage, bool walking) {
    final amount = stage.clamp(0, 3) / 3;
    final head = ((.62 - p.dy) / .28).clamp(0.0, 1.0);
    return Offset(
      .5 + (p.dx - .5) * (1 - .13 * amount * head),
      p.dy - (walking ? .035 : .075) * amount * (1 - p.dy) * p.dy * 4,
    );
  }

  void _tailMesh(Canvas canvas, Size size, int index) {
    final frame = atlas.frames[index], source = atlas.frames[index].source;
    final target = destination(atlas, index, size);
    const columns = 24, rows = 24;
    final positions = Float32List((columns + 1) * (rows + 1) * 2);
    final textures = Float32List(positions.length);
    var at = 0;
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final p = Offset(column / columns, row / rows);
        final tail = tailWarp(
          p,
          (frame.anchorX - source.left) / source.width,
          index < 6 ? pose.tailSwing : 0,
        );
        final warped = growthWarp(tail, growthStage, index >= 6);
        positions[at] = target.left + warped.dx * target.width;
        textures[at++] = source.left + p.dx * source.width;
        positions[at] = target.top + warped.dy * target.height;
        textures[at++] = source.top + p.dy * source.height;
      }
    }
    final indices = <int>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final a = row * (columns + 1) + col, b = a + columns + 1;
        indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
      }
    }
    final shader = ImageShader(
      atlas.image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    );
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: textures,
      indices: Uint16List.fromList(indices),
    );
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.medium,
    );
    vertices.dispose();
    shader.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    if (pose.mirror) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    if (pose.mix > 0 && pose.nextFrame != pose.frame) {
      canvas.saveLayer(Offset.zero & size, Paint());
      _frame(canvas, size, pose.frame, 1 - pose.mix);
      // Add alpha-premultiplied frames without darkening translucent fur.
      canvas.drawImageRect(
        atlas.image,
        atlas.frames[pose.nextFrame].source,
        destination(atlas, pose.nextFrame, size),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..blendMode = BlendMode.plus
          ..color = Colors.white.withValues(alpha: pose.mix),
      );
      canvas.restore();
    } else {
      _frame(canvas, size, pose.frame, 1);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CompanionMotionPainter old) =>
      old.growthStage != growthStage ||
      old.atlas != atlas ||
      old.pose.frame != pose.frame ||
      old.pose.nextFrame != pose.nextFrame ||
      old.pose.mix != pose.mix ||
      old.pose.tailSwing != pose.tailSwing ||
      old.pose.mirror != pose.mirror;
}
