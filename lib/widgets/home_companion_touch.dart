import 'package:flutter/material.dart';
import '../models/companion_behavior.dart';
import 'companion_presence.dart';

/// A purely visual greeting; touching the cat never changes care or rewards.
class HomeCompanionTouch extends StatefulWidget {
  const HomeCompanionTouch({
    super.key,
    required this.name,
    required this.enabled,
    required this.bondStage,
  });
  final String name;
  final bool enabled;
  final int bondStage;
  @override
  State<HomeCompanionTouch> createState() => _HomeCompanionTouchState();
}

class _HomeCompanionTouchState extends State<HomeCompanionTouch>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _foreground = true;
  bool get _canMove =>
      widget.enabled &&
      _foreground &&
      TickerMode.of(context) &&
      !MediaQuery.disableAnimationsOf(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _stopIfNeeded() {
    if (!_canMove) _reaction.reset();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stopIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HomeCompanionTouch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _stopIfNeeded();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _stopIfNeeded();
  }

  void _pet() {
    if (_canMove) {
      if (!_reaction.isAnimating) _reaction.forward(from: 0);
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('${widget.name}에게 마음을 전했어요.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${widget.name} 쓰다듬기',
    child: GestureDetector(
      key: const Key('home-companion-touch'),
      behavior: HitTestBehavior.opaque,
      onTap: _pet,
      child: AnimatedBuilder(
        animation: _reaction,
        builder: (context, _) {
          final reacting = _reaction.isAnimating && _canMove;
          return Stack(
            fit: StackFit.expand,
            children: [
              CompanionPresence(
                enabled: widget.enabled,
                bondStage: widget.bondStage,
                interaction: reacting ? CompanionInteraction.petting : null,
                interactionProgress: _reaction.value,
              ),
              if (reacting)
                const Positioned(
                  top: 10,
                  right: 18,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.favorite_rounded,
                      key: Key('home-petting-heart'),
                      color: Color(0xFFE6A5A0),
                      size: 25,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}
