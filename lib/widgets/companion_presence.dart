import 'package:flutter/material.dart';
import '../models/companion_behavior.dart';
import '../mongi/widgets/garden_ambient.dart';

/// The same quiet host on every surface. This clock never writes care records.
class CompanionPresence extends StatefulWidget {
  final bool enabled, resting, night;
  final int bondStage;
  final CompanionInteraction? interaction;
  final double interactionProgress;
  const CompanionPresence({
    super.key,
    this.enabled = true,
    this.resting = false,
    this.night = false,
    this.bondStage = 0,
    this.interaction,
    this.interactionProgress = 0,
  });
  @override
  State<CompanionPresence> createState() => _CompanionPresenceState();
}

class _CompanionPresenceState extends State<CompanionPresence>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 72),
  );
  bool _foreground = true, _allowed = false;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    _allowed =
        widget.enabled &&
        !widget.resting &&
        widget.interaction == null &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (_allowed) {
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
  void didUpdateWidget(covariant CompanionPresence old) {
    super.didUpdateWidget(old);
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
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final interacting =
            widget.interaction != null &&
            _foreground &&
            !MediaQuery.disableAnimationsOf(context) &&
            TickerMode.of(context) &&
            (ModalRoute.of(context)?.isCurrent ?? true);
        final frame = interacting
            ? CompanionBehaviorFrame.reacting(
                widget.interaction!,
                widget.interactionProgress,
              )
            : _allowed
            ? CompanionBehaviorFrame.at(
                _clock.value * 72,
                bondStage: widget.bondStage,
                night: widget.night,
              )
            : CompanionBehaviorFrame.still;
        return GardenCatArt(
          animation: _clock,
          naturalMotion: true,
          loafMotion: widget.enabled,
          motionSeconds: interacting
              ? widget.interactionProgress * 2.4
              : _clock.value * 72,
          tailMotion: _allowed || interacting,
          smiling:
              interacting &&
                  widget.interaction != CompanionInteraction.resting ||
              _allowed &&
                  frame.behavior == CompanionBehavior.greeting &&
                  _clock.value * 72 > 2.7 &&
                  _clock.value * 72 < 4.2,
          blinking: _allowed,
          resting: widget.resting || widget.interaction == CompanionInteraction.resting,
          headTilt: frame.headTilt,
          eyeClosure: widget.resting ? 1 : frame.eyeClosure,
          breath: frame.breath,
        );
      },
    ),
  );
}
