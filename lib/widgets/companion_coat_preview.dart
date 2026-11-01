import 'package:flutter/material.dart';
import '../models/companion_coat.dart';
import '../models/companion_motion.dart';
import 'companion_coat_art.dart';

class CompanionCoatPreview extends StatefulWidget {
  final CompanionCoat coat;
  const CompanionCoatPreview({super.key, required this.coat});
  @override
  State<CompanionCoatPreview> createState() => _CompanionCoatPreviewState();
}

class _CompanionCoatPreviewState extends State<CompanionCoatPreview>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _foreground = true, _enabled = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    _enabled =
        _foreground &&
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (_enabled) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) setState(_sync);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) => CompanionCoatArt(
      coat: widget.coat,
      motion: _enabled
          ? CompanionMotionPose.preview(
              _clock.value * 12 + widget.coat.index * .2,
            )
          : CompanionMotionPose.still,
    ),
  );
}
