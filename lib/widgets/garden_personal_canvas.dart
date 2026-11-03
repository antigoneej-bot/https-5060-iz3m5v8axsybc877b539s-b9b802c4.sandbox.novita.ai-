import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../services/cat_care_service.dart';
import '../services/garden_personal_gallery_store.dart';
import '../screens/garden_gallery_screen.dart';
import '../utils/private_gallery_png.dart';

/// Capture the rendered garden only, keeping the camera buttons out of photos.
class GardenPersonalCanvas extends StatefulWidget {
  const GardenPersonalCanvas({
    super.key,
    required this.builder,
    this.enabled = true,
    this.topPadding = 8,
    this.showControls = true,
    this.prefetched = false,
    this.initialArtwork,
  });
  final Widget Function(Uint8List? artwork) builder;
  final bool enabled;
  final double topPadding;
  final bool showControls;
  final bool prefetched;
  final Uint8List? initialArtwork;
  @override
  State<GardenPersonalCanvas> createState() => _GardenPersonalCanvasState();
}

class _GardenPersonalCanvasState extends State<GardenPersonalCanvas> {
  final capture = GlobalKey();
  final owner = CatCareService.localOwner;
  Uint8List? artwork;
  bool busy = false;
  bool _loaded = false;
  int _revision = -1;
  int request = 0;
  @override
  void initState() {
    super.initState();
    GardenPersonalGalleryStore.changes.addListener(load);
    if (widget.prefetched) {
      artwork = widget.initialArtwork;
      _loaded = true;
      _revision = GardenPersonalGalleryStore.changes.value;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active =
        TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);
    if (active &&
        (!_loaded || _revision != GardenPersonalGalleryStore.changes.value))
      load();
  }

  @override
  void didUpdateWidget(covariant GardenPersonalCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prefetched &&
        !identical(oldWidget.initialArtwork, widget.initialArtwork)) {
      artwork = widget.initialArtwork;
      _loaded = true;
      _revision = GardenPersonalGalleryStore.changes.value;
    }
  }

  @override
  void dispose() {
    GardenPersonalGalleryStore.changes.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    if (!mounted ||
        !TickerMode.of(context) ||
        !(ModalRoute.of(context)?.isCurrent ?? true))
      return;
    final ticket = ++request;
    try {
      final data = await GardenPersonalGalleryStore.read(owner);
      if (mounted && ticket == request && owner == CatCareService.localOwner) {
        setState(() {
          artwork = data['artwork'] == null
              ? null
              : base64Decode(data['artwork'] as String);
          _loaded = true;
          _revision = GardenPersonalGalleryStore.changes.value;
        });
      }
    } catch (_) {
      /* The garden remains usable; album offers an explicit retry. */
    }
  }

  void message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> photograph() async {
    if (busy || !widget.enabled || owner != CatCareService.localOwner) return;
    setState(() => busy = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !widget.enabled) return;
      final boundary = capture.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) throw StateError('capture');
      final longest = boundary.size.longestSide;
      final image = await boundary.toImage(
        pixelRatio: longest > 640 ? 640 / longest : 1,
      );
      try {
        final png = await privateGalleryPng(image);
        await GardenPersonalGalleryStore.addPhoto(owner, png);
      } finally {
        image.dispose();
      }
      message('정원 사진첩에 저장했어요.');
    } catch (e) {
      message(
        e is StateError ? e.message.toString() : '사진을 저장하지 못했어요. 다시 시도해 주세요.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> album() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GardenGalleryScreen()),
    );
    if (mounted) await load();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      RepaintBoundary(
        key: capture,
        child: widget.builder(
          owner == CatCareService.localOwner ? artwork : null,
        ),
      ),
      if (widget.showControls)
        Positioned(
          top: widget.topPadding,
          right: 8,
          child: SafeArea(
            left: false,
            bottom: false,
            child: Material(
              color: const Color(0xEFFFFFFF),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '정원 사진 찍기',
                    onPressed: widget.enabled && !busy ? photograph : null,
                    icon: Icon(
                      busy ? Icons.hourglass_top : Icons.photo_camera_outlined,
                    ),
                  ),
                  IconButton(
                    tooltip: '정원 사진첩·전시 관리',
                    onPressed: widget.enabled && !busy ? album : null,
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
