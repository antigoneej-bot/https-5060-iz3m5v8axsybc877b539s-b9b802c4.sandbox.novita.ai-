import '../models/companion_coat.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_language.dart';
import '../models/companion_behavior.dart';
import '../models/companion_motion.dart';
import '../providers/cat_care_provider.dart';
import 'companion_coat_art.dart';
import 'companion_presence.dart';

/// A companion invitation. Starting or cancelling never records completion.
class CompanionTogetherDialog extends StatefulWidget {
  const CompanionTogetherDialog({
    super.key,
    required this.activity,
    required this.invitation,
  });
  final String activity, invitation;
  @override
  State<CompanionTogetherDialog> createState() =>
      _CompanionTogetherDialogState();
}

class _CompanionTogetherDialogState extends State<CompanionTogetherDialog>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  bool _foreground = true;
  bool get _enabled =>
      context.read<CatCareProvider>().journey.automaticBehavior &&
      _foreground &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.of(context);
  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    if (_enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
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
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final coat = care.journey.coat ?? CompanionCoat.ginger;
    return AlertDialog(
      title: Text(tr(widget.invitation)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(care.displayName),
            SizedBox(
              width: 210,
              height: 180,
              child: CompanionCoatScope(
                useLocalChoice: true,
                coat: coat,
                growthStage: care.journey.keepBaby ? 0 : care.journey.stage,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, _) {
                    if (widget.activity == '산책하기' && _enabled) {
                      return CompanionCoatArt(
                        coat: coat,
                        motion: CompanionMotionPose.walk(
                          (_motion.value * 16).floor(),
                        ),
                      );
                    }
                    return CompanionPresence(
                      enabled: _enabled,
                      interaction: _enabled && widget.activity == '운동하기'
                          ? CompanionInteraction.playing
                          : null,
                      interactionProgress: _motion.value,
                    );
                  },
                ),
              ),
            ),
            Text(tr('편한 만큼 함께하고 돌아와 줘. 끝나면 아래 버튼을 눌러 줘.')),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('together-later'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(tr('나중에')),
        ),
        FilledButton(
          key: const Key('together-done'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(tr('함께 했어')),
        ),
      ],
    );
  }
}
