import '../l10n/app_language.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';

/// A quiet, non-verbal receipt shown only after the original letter is saved.
/// The cat keeps both paws grounded; its two original frames only blink.
class CalmLetterReceipt extends StatefulWidget {
  const CalmLetterReceipt({super.key});
  @override
  State<CalmLetterReceipt> createState() => _CalmLetterReceiptState();
}

class _CalmLetterReceiptState extends State<CalmLetterReceipt>
    with WidgetsBindingObserver {
  Timer? _blinkTimer;
  Timer? _openTimer;
  bool _blink = false;
  bool _active = true;
  bool _motion = false;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion =
        !MediaQuery.disableAnimationsOf(context) && TickerMode.of(context);
    if (_motion != motion) {
      _motion = motion;
      _syncBlink();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _syncBlink();
  }

  void _syncBlink() {
    _blinkTimer?.cancel();
    _openTimer?.cancel();
    if (_blink && mounted) setState(() => _blink = false);
    if (!_motion || !_active) return;
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 4700), (_) {
      if (!mounted) return;
      setState(() => _blink = true);
      _openTimer = Timer(const Duration(milliseconds: 145), () {
        if (mounted) setState(() => _blink = false);
      });
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _openTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ExcludeSemantics(
        child: SizedBox(
          width: 104,
          height: 106,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.asset(
                _blink
                    ? 'assets/living_garden/cat_idle_front_blink.webp'
                    : 'assets/living_garden/cat_idle_front.webp',
                width: 90,
                height: 100,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: _motion
                      ? const Duration(milliseconds: 450)
                      : Duration.zero,
                  builder: (_, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 30,
                    color: AppColors.catSage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        tr("편지를 조용히 담아두었어요"),
        textAlign: TextAlign.center,
        style: titleFont(fontSize: 20, color: AppColors.ink),
      ),
      const SizedBox(height: 6),
      Text(
        tr("지금의 마음 그대로, 기록에 남아 있어요."),
        textAlign: TextAlign.center,
        style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
      ),
    ],
  );
}
