import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Only the explicitly selected, visible card plays. Posters need no decoder.
class EmotionCatVideo extends StatefulWidget {
  final String imageAsset;
  final String? videoAsset;
  const EmotionCatVideo({super.key, required this.imageAsset, this.videoAsset});
  @override
  State<EmotionCatVideo> createState() => _EmotionCatVideoState();
}

class _EmotionCatVideoState extends State<EmotionCatVideo>
    with WidgetsBindingObserver {
  static final ValueNotifier<Object?> _active = ValueNotifier(null);
  final Object _identity = Object();
  VideoPlayerController? _player;
  ScrollPosition? _scroll;
  bool _loading = false, _failed = false, _foreground = true;
  bool _allowed = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _active.addListener(_activeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _scroll) {
      _scroll?.removeListener(_checkVisibility);
      _scroll = next;
      _scroll?.addListener(_checkVisibility);
    }
    _allowed =
        TickerMode.of(context) &&
        !MediaQuery.disableAnimationsOf(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkVisibility();
    });
  }

  void _activeChanged() {
    if (_active.value != _identity) {
      _player?.pause();
    }
    if (mounted) setState(() {});
  }

  void _stop() {
    if (_active.value == _identity) _active.value = null;
  }

  void _checkVisibility() {
    if (!mounted || _active.value != _identity) return;
    final box = context.findRenderObject();
    if (!_allowed || !_foreground || box is! RenderBox || !box.hasSize) {
      _stop();
      return;
    }
    final bounds = box.localToGlobal(Offset.zero) & box.size;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    final visible = viewport is RenderBox && viewport.hasSize
        ? viewport.localToGlobal(Offset.zero) & viewport.size
        : Offset.zero & MediaQuery.sizeOf(context);
    final overlap = bounds.intersect(visible);
    if (overlap.isEmpty ||
        overlap.width * overlap.height < bounds.width * bounds.height * .5) {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _stop();
  }

  Future<void> _toggle() async {
    if (_active.value == _identity) {
      _stop();
      return;
    }
    if (_loading || !_allowed || !_foreground || widget.videoAsset == null) {
      return;
    }
    _active.value = _identity;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      if (_player == null) {
        final player = VideoPlayerController.asset(widget.videoAsset!);
        _player = player;
        await player.initialize();
        if (!mounted || _player != player) return;
        await player.setVolume(0);
        await player.setLooping(true);
      }
      if (!mounted) return;
      _checkVisibility();
      if (_active.value == _identity && _allowed && _foreground) {
        await _player!.play();
      }
    } catch (_) {
      _stop();
      final player = _player;
      _player = null;
      await player?.dispose();
      if (mounted) _failed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _scroll?.removeListener(_checkVisibility);
    WidgetsBinding.instance.removeObserver(this);
    _active.removeListener(_activeChanged);
    _stop();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing =
        _active.value == _identity && (_player?.value.isInitialized ?? false);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(widget.imageAsset, fit: BoxFit.cover, cacheWidth: 300),
        if (playing)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _player!.value.size.width,
              height: _player!.value.size.height,
              child: VideoPlayer(_player!),
            ),
          ),
        if (widget.videoAsset != null && _allowed)
          Positioned(
            right: 2,
            bottom: 2,
            child: IconButton.filledTonal(
              tooltip: _failed
                  ? '영상 다시 불러오기'
                  : playing
                  ? '움직임 멈추기'
                  : '움직임 보기',
              onPressed: _loading ? null : _toggle,
              iconSize: 20,
              icon: Icon(
                _loading
                    ? Icons.hourglass_top
                    : playing
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
          ),
      ],
    );
  }
}
