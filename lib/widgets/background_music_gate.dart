import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/sound_service.dart';

/// Lives inside AppLockGate, above the navigator. A page push does not pause
/// music, but app backgrounding and the privacy lock do.
class BackgroundMusicGate extends StatefulWidget {
  final Widget child;
  final SoundService? sound;
  const BackgroundMusicGate({super.key, required this.child, this.sound});

  @override
  State<BackgroundMusicGate> createState() => _BackgroundMusicGateState();
}

class _BackgroundMusicGateState extends State<BackgroundMusicGate>
    with WidgetsBindingObserver {
  late final _sound = widget.sound ?? SoundService();
  bool _visible = false;
  bool _foreground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _sync() {
    unawaited(
      _sound
          .setAppAudible(_foreground && _visible, autoplay: !kIsWeb)
          .catchError((Object _) {}),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.of(context);
    if (!_visible) _sync();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sound.setAppAudible(false).catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    // Browsers may require a user gesture. Listening to pointer-down also
    // works on buttons; it does not compete with their gesture recognizers.
    onPointerDown: (_) {
      if (_foreground && _visible) unawaited(_sound.tryStartBgm());
    },
    child: widget.child,
  );
}
