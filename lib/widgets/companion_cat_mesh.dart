import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// One continuous textured surface. The neck blends into the fixed body;
/// the lower body and paws stay at their original positions. No detached body layers.
class CompanionCatMesh extends StatefulWidget {
  final double headTilt, eyeClosure, breath;
  const CompanionCatMesh({
    super.key,
    this.headTilt = 0,
    this.eyeClosure = 0,
    this.breath = 1,
  });
  @override
  State<CompanionCatMesh> createState() => _CompanionCatMeshState();
}

class _CompanionCatMeshState extends State<CompanionCatMesh> {
  ImageStream? _openStream, _closedStream;
  ImageInfo? _open, _closed;
  late final ImageStreamListener _openListener = ImageStreamListener((info, _) {
    if (!mounted) {
      info.dispose();
      return;
    }
    setState(() {
      _open?.dispose();
      _open = info;
    });
  }, onError: (_, __) {});
  late final ImageStreamListener _closedListener = ImageStreamListener((
    info,
    _,
  ) {
    if (!mounted) {
      info.dispose();
      return;
    }
    setState(() {
      _closed?.dispose();
      _closed = info;
    });
  }, onError: (_, __) {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final configuration = createLocalImageConfiguration(context);
    final open = const AssetImage(
      'assets/living_garden/cat_idle_front.webp',
    ).resolve(configuration);
    final closed = const AssetImage(
      'assets/living_garden/cat_idle_front_blink.webp',
    ).resolve(configuration);
    if (_openStream?.key != open.key) {
      _openStream?.removeListener(_openListener);
      _openStream = open..addListener(_openListener);
    }
    if (_closedStream?.key != closed.key) {
      _closedStream?.removeListener(_closedListener);
      _closedStream = closed..addListener(_closedListener);
    }
  }

  @override
  void dispose() {
    _openStream?.removeListener(_openListener);
    _closedStream?.removeListener(_closedListener);
    _open?.dispose();
    _closed?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _open == null
      ? Image.asset(
          'assets/living_garden/cat_idle_front.webp',
          excludeFromSemantics: true,
        )
      : CustomPaint(
          painter: CompanionCatMeshPainter(
            open: _open!.image,
            closed: _closed?.image,
            headTilt: widget.headTilt,
            eyeClosure: widget.eyeClosure,
            breath: widget.breath,
          ),
        );
}

class CompanionCatMeshPainter extends CustomPainter {
  final ui.Image open;
  final ui.Image? closed;
  final double headTilt, eyeClosure, breath;
  CompanionCatMeshPainter({
    required this.open,
    this.closed,
    required this.headTilt,
    required this.eyeClosure,
    this.breath = 1,
  });

  /// Normalized geometry is independently tested; all points below the neck
  /// remain identical for every pose, including both paws and their shadows.
  static Offset warp(Offset p, double tilt, {double breath = 1}) {
    final t = ((.67 - p.dy) / .19).clamp(0.0, 1.0);
    final weight = t * t * (3 - 2 * t);
    final angle = tilt.clamp(-.045, .045) * weight;
    const pivot = Offset(.49, .51);
    final v = p - pivot;
    final rotated =
        pivot +
        Offset(
          v.dx * math.cos(angle) - v.dy * math.sin(angle),
          v.dx * math.sin(angle) + v.dy * math.cos(angle),
        );
    return Offset(
      rotated.dx,
      rotated.dy +
          (rotated.dy - .67) * (breath.clamp(.997, 1.003) - 1) * weight,
    );
  }

  void _paintImage(Canvas canvas, Size size, ui.Image image, double opacity) {
    const columns = 24, rows = 28;
    final positions = Float32List((columns + 1) * (rows + 1) * 2);
    final texture = Float32List(positions.length);
    var offset = 0;
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        final p = Offset(column / columns, row / rows);
        final transformed = warp(p, headTilt, breath: breath);
        positions[offset] = transformed.dx * size.width;
        texture[offset++] = p.dx * image.width;
        positions[offset] = transformed.dy * size.height;
        texture[offset++] = p.dy * image.height;
      }
    }
    final indices = <int>[];
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final a = row * (columns + 1) + column, b = a + columns + 1;
        indices.addAll([a, b, a + 1, a + 1, b, b + 1]);
      }
    }
    final shader = ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    );
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texture,
      indices: Uint16List.fromList(indices),
    );
    canvas.drawVertices(
      vertices,
      BlendMode.srcOver,
      Paint()
        ..shader = shader
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withValues(alpha: opacity),
    );
    vertices.dispose();
    shader.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // The source assets are square; match Image.asset's contain behavior.
    final side = math.min(size.width, size.height);
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    final square = Size.square(side);
    _paintImage(canvas, square, open, 1);
    if (closed != null && eyeClosure > 0) {
      final eyes = Path()
        ..addOval(
          Rect.fromLTRB(side * .303, side * .320, side * .465, side * .438),
        )
        ..addOval(
          Rect.fromLTRB(side * .523, side * .320, side * .676, side * .438),
        );
      // Both eyes lie in the rigid head section of the continuous surface.
      final matrix = Matrix4.identity()
        ..translateByDouble(0.0, side * .67, 0.0, 1.0)
        ..scaleByDouble(1.0, breath.clamp(.997, 1.003), 1.0, 1.0)
        ..translateByDouble(0.0, -side * .67, 0.0, 1.0)
        ..translateByDouble(side * .49, side * .51, 0.0, 1.0)
        ..rotateZ(headTilt.clamp(-.045, .045))
        ..translateByDouble(-side * .49, -side * .51, 0.0, 1.0);
      canvas.save();
      canvas.clipPath(eyes.transform(matrix.storage));
      _paintImage(canvas, square, closed!, eyeClosure.clamp(0.0, 1.0));
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CompanionCatMeshPainter old) =>
      old.open != open ||
      old.closed != closed ||
      old.headTilt != headTilt ||
      old.eyeClosure != eyeClosure ||
      old.breath != breath;
}
