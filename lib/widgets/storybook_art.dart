import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/companion_coat.dart';

const storyAssets = 'assets/storybook_ui_v1/';

/// Reuses decoded atlas images. Labels and interactive controls remain native.
class StorySprite extends StatefulWidget {
  const StorySprite.icon(this.index, {super.key})
    : coat = null,
      sleeping = false;
  const StorySprite.cat(this.coat, {super.key, this.sleeping = false})
    : index = -1;
  final int index;
  final CompanionCoat? coat;
  final bool sleeping;
  @override
  State<StorySprite> createState() => _StorySpriteState();
}

class _StorySpriteState extends State<StorySprite> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener((info, _) {
    if (!mounted) {
      info.dispose();
      return;
    }
    final previous = _info;
    setState(() => _info = info);
    previous?.dispose();
  }, onError: (Object _, StackTrace? __) {});
  String? _asset;

  void _resolve() {
    final asset =
        '$storyAssets${widget.coat == null ? 'illustration' : 'companion'}-atlas.png';
    if (_asset == asset) return;
    _asset = asset;
    _stream?.removeListener(_listener);
    _info?.dispose();
    _info = null;
    _stream = AssetImage(asset).resolve(createLocalImageConfiguration(context));
    _stream!.addListener(_listener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant StorySprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolve();
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _info?.image;
    if (image == null) return const SizedBox.expand();
    Rect source;
    if (widget.coat == null) {
      final index = widget.index.clamp(0, 24);
      source = Rect.fromLTWH((index % 5) / 5, (index ~/ 5) / 5, .2, .2);
    } else {
      final index = widget.coat!.index;
      final column = index % 3;
      final row = index ~/ 3 + (widget.sleeping ? 2 : 0);
      // The approved watercolor sheet has tall seated rows and shorter sleeping rows.
      const ys = [0.0, .294, .585, .785, 1.0];
      final xs = widget.sleeping
          ? const [0.0, .345, .675, 1.0]
          : const [0.0, .365, .715, 1.0];
      source = Rect.fromLTRB(xs[column], ys[row], xs[column + 1], ys[row + 1]);
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: _SpritePainter(image, source),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter(this.image, this.source);
  final ui.Image image;
  final Rect source;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final src = Rect.fromLTWH(
      source.left * image.width,
      source.top * image.height,
      source.width * image.width,
      source.height * image.height,
    );
    final fitted = applyBoxFit(BoxFit.contain, src.size, size);
    final dst = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _SpritePainter old) =>
      old.image != image || old.source != source;
}
