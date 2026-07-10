import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme.dart';

/// 앱을 실행할 때마다 가장 먼저 보여주는 짧은 인트로 영상 화면.
/// 브라우저 자동재생 정책 때문에 기본은 무음으로 재생하고,
/// 사용자가 원하면 소리를 켤 수 있도록 아이콘을 제공합니다.
/// 영상이 끝나거나 사용자가 건너뛰기를 누르면 [onFinished]를 호출합니다.
class VideoIntroScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const VideoIntroScreen({super.key, required this.onFinished});

  @override
  State<VideoIntroScreen> createState() => _VideoIntroScreenState();
}

class _VideoIntroScreenState extends State<VideoIntroScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _muted = true;
  bool _finishing = false;
  bool _ended = false;
  late final AnimationController _fadeIn;
  late final AnimationController _fadeOut;

  /// 영상이 끝난 뒤(로고 장면) 이 시간만큼 화면에 더 머무르다가 페이드아웃합니다.
  /// 너무 급하게 끝나는 느낌을 줄이기 위한 여운 구간입니다.
  static const Duration _endingHold = Duration(milliseconds: 1600);
  static const Duration _fadeOutDuration = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeOut = AnimationController(vsync: this, duration: _fadeOutDuration);
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.asset('assets/video/intro.mp4');
      await controller.initialize();
      await controller.setVolume(0); // 자동재생 정책 대응: 기본 무음
      controller.addListener(_onTick);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (_) {
      // 영상 로드 실패 시 앱 진입을 막지 않고 바로 넘어갑니다.
      _finish();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (_ended || _finishing) return;
    if (!c.value.isPlaying &&
        c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero) {
      _onVideoEnded();
    }
  }

  /// 영상 재생이 끝났을 때: 곧바로 넘어가지 않고, 마지막 장면(로고)에서
  /// 잠시 머무른 뒤 부드럽게 페이드아웃하고 다음 화면으로 넘어갑니다.
  void _onVideoEnded() {
    _ended = true;
    setState(() {});
    Future.delayed(_endingHold, () {
      if (!mounted || _finishing) return;
      _fadeOut.forward();
    });
    Future.delayed(_endingHold + _fadeOutDuration, _finish);
  }

  void _finish() {
    if (_finishing) return;
    _finishing = true;
    widget.onFinished();
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _muted = !_muted;
      c.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _fadeIn.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleMute,
        child: AnimatedBuilder(
          animation: _fadeOut,
          builder: (context, child) {
            return Opacity(opacity: 1 - _fadeOut.value, child: child);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_ready && controller != null)
                FadeTransition(
                  opacity: _fadeIn,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                )
              else
                Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.gold.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              // 건너뛰기 버튼 (영상이 끝난 여운 구간에서는 굳이 필요 없으므로 숨김)
              if (!_ended)
                Positioned(
                  top: 48,
                  right: 20,
                  child: SafeArea(child: _SkipButton(onTap: _finish)),
                ),
              // 음소거 토글 표시
              if (_ready && !_ended)
                Positioned(
                  bottom: 40,
                  right: 20,
                  child: SafeArea(
                    child: _MuteIndicator(muted: _muted, onTap: _toggleMute),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '건너뛰기',
                style: bodyFont(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MuteIndicator extends StatelessWidget {
  final bool muted;
  final VoidCallback onTap;
  const _MuteIndicator({required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            size: 17,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}
