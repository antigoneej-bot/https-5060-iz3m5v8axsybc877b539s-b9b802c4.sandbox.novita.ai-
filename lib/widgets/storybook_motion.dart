import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative motion only: never intercepts taps or changes saved state.
class StorybookMotion extends StatefulWidget {
  const StorybookMotion({
    super.key,
    required this.enabled,
    this.child,
    this.breathing = false,
  });
  final bool enabled, breathing;
  final Widget? child;
  @override
  State<StorybookMotion> createState() => _StorybookMotionState();
}

class _StorybookMotionState extends State<StorybookMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _sync() {
    final run =
        widget.enabled &&
        _foreground &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true) &&
        !MediaQuery.disableAnimationsOf(context);
    if (run && !_clock.isAnimating) _clock.repeat();
    if (!run) {
      _clock.stop();
      _clock.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant StorybookMotion oldWidget) {
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
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: widget.breathing
            ? AnimatedBuilder(
                animation: _clock,
                child: widget.child,
                builder: (_, child) {
                  final breath = (1 - math.cos(_clock.value * math.pi * 8)) / 2;
                  return Transform.scale(
                    scaleY: 1 + breath * .012,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  );
                },
              )
            : CustomPaint(painter: _StoryLight(_clock)),
      ),
    ),
  );
}

class _StoryLight extends CustomPainter {
  _StoryLight(this.clock) : super(repaint: clock);
  final Animation<double> clock;
  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    // A slow soft wash, strongest in the illustration's lower half.
    final x = size.width * (-.5 + 2 * t);
    final wash = Rect.fromLTWH(
      x - size.width * .28,
      size.height * .30,
      size.width * .56,
      size.height * .70,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
      wash,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x00FFF2BD), Color(0x20FFF2BD), Color(0x00FFF2BD)],
        ).createShader(wash),
    );
    for (var i = 0; i < 12; i++) {
      final phase = (t * 2 + i * .173) % 1;
      final glow = math.pow(math.sin(phase * math.pi), 4).toDouble();
      final p = Offset(
        size.width * (.08 + (i * .237) % .84),
        size.height * (.38 + (i * .131) % .53) -
            math.sin(t * math.pi * 2 + i) * 3,
      );
      final paint = Paint()
        ..color = const Color(0xFFFFF4CB).withValues(alpha: glow * .7)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final radius = 1.5 + glow * 2;
      canvas.drawLine(p - Offset(radius, 0), p + Offset(radius, 0), paint);
      canvas.drawLine(p - Offset(0, radius), p + Offset(0, radius), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StoryLight oldDelegate) =>
      oldDelegate.clock != clock;
}
