import '../l10n/app_language.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/sound_service.dart';

/// Dedicated tucked-paw art; no changes to the standing/walking sprites.
class CompanionLoafArt extends StatefulWidget {
  final int coatIndex;
  final bool motionEnabled;
  const CompanionLoafArt({
    super.key,
    this.coatIndex = 0,
    this.motionEnabled = true,
  });
  @override
  State<CompanionLoafArt> createState() => _CompanionLoafArtState();
}

class _CompanionLoafArtState extends State<CompanionLoafArt>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static _CompanionLoafArtState? _audioOwner;
  static Future<ui.Image>? _image;
  static ui.Image? _decoded;
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  final _sound = SoundService();
  Timer? _purr;
  bool _foreground = true, _ready = false, _active = false;

  static Future<ui.Image> _load() async {
    try {
      final data = await rootBundle.load(
        'assets/living_garden/companion_loaf.png',
      );
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      final image = (await codec.getNextFrame()).image;
      codec.dispose();
      return _decoded = image;
    } catch (_) {
      _image = null;
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _sound.addListener(_sync);
    _purr = Timer.periodic(const Duration(seconds: 8), (_) => _purrOnce());
  }

  void _purrOnce() {
    if (!mounted ||
        !_active ||
        !_sound.sfxEnabled ||
        _sound.gardenSuspended ||
        _sound.narrationPlaying)
      return;
    if (_audioOwner != null && _audioOwner != this) return;
    _audioOwner = this;
    unawaited(_sound.playPurr());
  }

  void _silence() {
    if (_audioOwner != this) return;
    _audioOwner = null;
    unawaited(_sound.stopPurr());
  }

  void _sync() {
    if (!_ready || !mounted) return;
    final wasActive = _active;
    _active =
        _foreground &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (_active &&
        widget.motionEnabled &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else {
      _breath.stop();
    }
    if (!_active ||
        !_sound.sfxEnabled ||
        _sound.gardenSuspended ||
        _sound.narrationPlaying) {
      _silence();
    } else if (!wasActive) {
      _purrOnce();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ready = true;
    _sync();
  }

  @override
  void didUpdateWidget(covariant CompanionLoafArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    _active = false;
    _purr?.cancel();
    _sound.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _silence();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: tr("앞발을 접고 식빵 자세로 골골거리며 쉬는 고양이"),
    image: true,
    child: FutureBuilder<ui.Image>(
      future: _decoded != null
          ? SynchronousFuture(_decoded!)
          : (_image ??= _load()),
      builder: (context, snapshot) => snapshot.hasData
          ? AnimatedBuilder(
              animation: _breath,
              builder: (context, _) => CustomPaint(
                painter: CompanionLoafPainter(
                  snapshot.data!,
                  widget.coatIndex,
                  .997 + _breath.value * .006,
                ),
              ),
            )
          : const SizedBox.expand(),
    ),
  );
}

class CompanionLoafPainter extends CustomPainter {
  final ui.Image image;
  final int coatIndex;
  final double breath;
  const CompanionLoafPainter(this.image, this.coatIndex, this.breath);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final index = coatIndex.clamp(0, 5).toInt();
    final cellW = image.width / 3, cellH = image.height / 2;
    final source = Rect.fromLTWH(
      (index % 3) * cellW,
      (index ~/ 3) * cellH,
      cellW,
      cellH,
    );
    final scale = math.min(size.width / cellW, size.height * .82 / cellH);
    final w = cellW * scale, h = cellH * scale * breath;
    // Measured contact line per row keeps the loaf grounded during breathing.
    final foot = index < 3 ? 476 / 512 : 428 / 512;
    canvas.drawImageRect(
      image,
      source,
      Rect.fromLTWH((size.width - w) / 2, size.height * .967 - h * foot, w, h),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(CompanionLoafPainter old) =>
      image != old.image || coatIndex != old.coatIndex || breath != old.breath;
}
