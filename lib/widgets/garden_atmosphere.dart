import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single clock drives the quiet decorations and floating cards.
/// Decoration never intercepts taps or enters the accessibility tree.
class GardenAtmosphere extends StatefulWidget {
  final Widget child;
  final bool motionEnabled;
  const GardenAtmosphere({
    super.key,
    required this.child,
    this.motionEnabled = true,
  });
  @override
  State<GardenAtmosphere> createState() => _GardenAtmosphereState();
}

class _GardenAtmosphereState extends State<GardenAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _foreground = true;
  bool get _moving =>
      _foreground &&
      widget.motionEnabled &&
      TickerMode.of(context) &&
      !MediaQuery.disableAnimationsOf(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true);
  void _sync() {
    if (_moving) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      _clock.value = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant GardenAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  Widget build(BuildContext context) => _AmbientClock(
    clock: _clock,
    moving: _moving,
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const Key('autumn-atmosphere'),
                  painter: _AtmospherePainter(_clock),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AmbientClock extends InheritedWidget {
  final Animation<double> clock;
  final bool moving;
  const _AmbientClock({
    required this.clock,
    required this.moving,
    required super.child,
  });
  @override
  bool updateShouldNotify(_AmbientClock oldWidget) =>
      moving != oldWidget.moving || clock != oldWidget.clock;
}

class FloatingGardenCard extends StatelessWidget {
  final Widget child;
  final double phase;
  const FloatingGardenCard({super.key, required this.child, this.phase = 0});
  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AmbientClock>();
    if (scope == null || !scope.moving || !TickerMode.of(context)) return child;
    return AnimatedBuilder(
      animation: scope.clock,
      child: child,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          math.sin(scope.clock.value * math.pi * 2 + phase) * .8,
          math.sin(scope.clock.value * math.pi * 4 + phase) * 2.2,
        ),
        child: child,
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final Animation<double> clock;
  _AtmospherePainter(this.clock) : super(repaint: clock);
  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;
    // Sparse, translucent bubbles stay mostly near the edges, away from text.
    for (var i = 0; i < 9; i++) {
      final x =
          size.width *
              (i.isEven ? .035 + (i % 3) * .055 : .965 - (i % 3) * .045) +
          math.sin(t * math.pi * 2 + i) * 10;
      final y =
          ((i / 9 - t * (i.isEven ? 1 : 2)) % 1) * (size.height + 60) - 30;
      final r = i % 3 == 0 ? 17.0 : 6.0 + i % 4;
      canvas.save();
      canvas.translate(x, y);
      final bubble = Path()
        ..moveTo(0, -r * 1.18)
        ..cubicTo(r * .45, -r * .65, r, r * .05, r, r * .35)
        ..cubicTo(r, r * 1.35, -r, r * 1.35, -r, r * .35)
        ..cubicTo(-r, r * .05, -r * .45, -r * .65, 0, -r * 1.18);
      canvas.drawPath(bubble, Paint()..color = const Color(0x22B4DACE));
      canvas.drawPath(
        bubble,
        Paint()
          ..color = const Color(0x559BC7BD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      canvas.drawOval(
        Rect.fromLTWH(-r * .55, -r * .45, r * .22, r * .5),
        Paint()..color = const Color(0xAAFFFFFF),
      );
      if (i % 3 == 0) {
        final face = Paint()
          ..color = const Color(0x8895ADA3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawPath(
          Path()
            ..moveTo(-8, 1)
            ..lineTo(-8, -7)
            ..lineTo(-3, -3)
            ..quadraticBezierTo(0, -5, 3, -3)
            ..lineTo(8, -7)
            ..lineTo(8, 1)
            ..quadraticBezierTo(8, 9, 0, 9)
            ..quadraticBezierTo(-8, 9, -8, 1),
          face,
        );
        canvas.drawCircle(const Offset(-3, 1), .8, face);
        canvas.drawCircle(const Offset(3, 1), .8, face);
        canvas.drawPath(
          Path()
            ..moveTo(-2, 4)
            ..quadraticBezierTo(0, 6, 2, 4),
          face,
        );
      }
      canvas.restore();
    }
    for (var i = 0; i < 14; i++) {
      final p = Offset(
        size.width * ((i * .618) % 1),
        size.height * ((i * .381 + t) % 1),
      );
      final alpha = (.15 + .22 * (.5 + .5 * math.sin(t * math.pi * 6 + i)));
      final paint = Paint()
        ..color = const Color(0xFFDCC582).withValues(alpha: alpha)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p - const Offset(3, 0), p + const Offset(3, 0), paint);
      canvas.drawLine(p - const Offset(0, 3), p + const Offset(0, 3), paint);
    }
    for (var i = 0; i < 6; i++) {
      final x =
          size.width * ((i * .173 + .08) % 1) +
          math.sin(t * math.pi * 4 + i) * 24;
      final y = ((t + i / 6) % 1) * (size.height + 50) - 25;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(t * math.pi * 2 + i) * .7 + i);
      final leaf = Path()
        ..moveTo(0, -9)
        ..cubicTo(12, -5, 9, 5, 0, 9)
        ..cubicTo(-9, 3, -7, -5, 0, -9);
      canvas.drawPath(
        leaf,
        Paint()
          ..color = [
            const Color(0x55DDAE6D),
            const Color(0x50D7AB93),
            const Color(0x55C6BC88),
          ][i % 3],
      );
      canvas.drawLine(
        const Offset(0, -6),
        const Offset(0, 10),
        Paint()
          ..color = const Color(0x508F8064)
          ..strokeWidth = .7,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter oldDelegate) =>
      clock != oldDelegate.clock;
}
