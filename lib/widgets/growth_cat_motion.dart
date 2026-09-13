import 'dart:math';
import 'package:flutter/material.dart';

enum GrowthCatReaction { greeting, curious, happy, bow }

/// Whole-art motion for the existing drawings; no invented in-between poses.
class GrowthCatMotion extends StatefulWidget {
  final String asset;
  final double size;
  final bool adult;
  final int reactionToken;
  const GrowthCatMotion({super.key, required this.asset, this.size = 132,
    this.adult = false, this.reactionToken = 0});
  @override
  State<GrowthCatMotion> createState() => _GrowthCatMotionState();
}
class _GrowthCatMotionState extends State<GrowthCatMotion>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _breath;
  late final AnimationController _reaction;
  GrowthCatReaction _kind = GrowthCatReaction.greeting;
  bool _foreground = true;
  bool _motionAllowed = false;
  int _nextReaction = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breath = AnimationController(vsync: this, duration: Duration(milliseconds: widget.adult ? 4800 : 3900));
    _reaction = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500), value: 1);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed = !MediaQuery.disableAnimationsOf(context) && TickerMode.of(context);
    _sync();
  }
  void _sync() {
    if (_foreground && _motionAllowed) {
      if (!_breath.isAnimating) _breath.repeat();
    } else {
      _breath.stop();
      _reaction.stop();
      _reaction.value = 1;
    }
  }
  @override
  void didUpdateWidget(covariant GrowthCatMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reactionToken != widget.reactionToken && _foreground && _motionAllowed && !_reaction.isAnimating) {
      const teen = [GrowthCatReaction.greeting, GrowthCatReaction.curious, GrowthCatReaction.happy];
      const adult = [GrowthCatReaction.greeting, GrowthCatReaction.bow, GrowthCatReaction.happy];
      final sequence = widget.adult ? adult : teen;
      _kind = sequence[_nextReaction++ % sequence.length];
      _reaction.forward(from: 0);
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breath.dispose(); _reaction.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => RepaintBoundary(child: SizedBox(
    width: widget.size, height: widget.size + 10,
    child: AnimatedBuilder(animation: Listenable.merge([_breath, _reaction]),
      child: Image.asset(widget.asset, width: widget.size, height: widget.size,
        fit: BoxFit.contain, cacheWidth: (widget.size * 2).round(),
        gaplessPlayback: true, excludeFromSemantics: true),
      builder: (_, child) {
        final enabled = _foreground && _motionAllowed;
        final t = enabled ? _reaction.value : 1.0;
        final pulse = pow(sin(pi * t), 2).toDouble();
        final intensity = widget.adult ? .7 : 1.0;
        final breath = enabled ? sin(_breath.value * 2 * pi) : 0.0;
        var angle = 0.0;
        var dy = 0.0;
        var squash = 0.0;
        switch (_kind) {
          case GrowthCatReaction.greeting: angle = .035 * sin(4 * pi * t) * pulse; break;
          case GrowthCatReaction.curious: angle = -.045 * pulse; break;
          case GrowthCatReaction.happy:
            dy = -widget.size * .035 * pow(sin(2 * pi * t), 2) * pulse;
            break;
          case GrowthCatReaction.bow: squash = -.04 * pulse; angle = .018 * pulse; break;
        }
        return Transform.translate(offset: Offset(0, dy * intensity), child: Transform.rotate(
          angle: angle * intensity, alignment: const Alignment(0, .7),
          child: Transform.scale(alignment: const Alignment(0, .7),
            scaleX: 1 - .003 * breath,
            scaleY: 1 + .009 * breath + squash * intensity,
            child: child),
        ));
      }),
  ));
}
