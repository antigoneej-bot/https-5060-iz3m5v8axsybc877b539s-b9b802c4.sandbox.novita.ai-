import '../services/access_policy.dart';
import '../services/subscription_service.dart';
import 'subscription_gate.dart';
import '../services/meditation_sleep_service.dart';
import '../services/meditation_library_store.dart';
import 'meditation_sleep_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:video_player/video_player.dart';
import '../theme.dart';
import 'dart:async';
import '../services/media_coordinator.dart';
import '../services/meditation_completion_service.dart';

/// 명상/움직임 가이드에 딸린 "영상으로 따라하기" 재생 위젯.
///
/// 개발자가 [assetPath]에 해당하는 영상 파일을 아직 넣지 않았다면
/// (=assets/video/meditation/{guideKey}.mp4 가 존재하지 않으면) 이 위젯은
/// 조용히 아무것도 그리지 않습니다(SizedBox.shrink). 즉, 영상을 하나씩
/// 촬영해서 넣을 때마다 해당 가이드에만 자연스럽게 재생 버튼이 나타나고,
/// 나머지 가이드는 지금처럼 텍스트 스텝만 보여주는 방식으로 점진적으로
/// 확장할 수 있습니다.
class MeditationVideoPlayer extends StatefulWidget {
  final String assetPath;
  final Color accent;
  const MeditationVideoPlayer({
    super.key,
    required this.assetPath,
    required this.accent,
  });

  @override
  State<MeditationVideoPlayer> createState() => _MeditationVideoPlayerState();
}

class _MeditationVideoPlayerState extends State<MeditationVideoPlayer>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _exists = false;
  bool _expanded = false;
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _completionRecorded = false;
  bool _sessionCompleted = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAssetExists();
  }

  /// pubspec.yaml에 영상 폴더 전체(assets/video/)가 등록되어 있어도,
  /// 실제로 그 이름의 파일이 없으면 로드 시 예외가 발생합니다. 이를 이용해
  /// "이 가이드의 영상이 아직 준비되지 않았다"를 조용히 감지합니다.
  Future<void> _checkAssetExists() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final exists = manifest.listAssets().contains(widget.assetPath);
      if (!mounted) return;
      setState(() {
        _exists = exists;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _exists = false;
        _checking = false;
      });
    }
  }

  Future<void> _pauseDirect() async {
    MeditationSleepService.instance.detach(this);
    await _controller?.pause();
  }

  Future<void> _play(VideoPlayerController controller) =>
      MediaCoordinator.instance.run(() async {
        if (!mounted || !_expanded || !_foreground) return;
        final key = widget.assetPath.split('/').last.split('.').first;
        if (!AccessPolicy.meditationAllowed(
          key,
          await SubscriptionService().isPremium(),
        )) {
          if (mounted) await requestSubscription(context);
          return;
        }
        await MediaCoordinator.instance.claim(this, _pauseDirect);
        await controller.setVolume(1);
        await controller.play();
        MeditationSleepService.instance.attach(
          this,
          volume: (factor) => MediaCoordinator.instance.run(() async {
            if (mounted &&
                identical(MeditationSleepService.instance.owner, this))
              await controller.setVolume(factor);
          }),
          stop: () => MediaCoordinator.instance.run(() async {
            await _pauseDirect();
            MediaCoordinator.instance.release(this);
          }),
        );
        unawaited(
          MeditationLibraryStore.instance
              .played(widget.assetPath.split('/').last.split('.').first)
              .catchError((Object _) {}),
        );
      });
  void _onProgress() {
    final value = _controller?.value;
    if (value == null || _completionRecorded || value.duration == Duration.zero)
      return;
    if (value.isCompleted) {
      _completionRecorded = true;
      final key = widget.assetPath.split('/').last.split('.').first;
      if (!_sessionCompleted) {
        _sessionCompleted = true;
        unawaited(MeditationCompletionService.instance.complete(guideKey: key));
      }
      final sleep = MeditationSleepService.instance;
      if (key == 'fireplaceRest' &&
          identical(sleep.owner, this) &&
          sleep.repeat &&
          (sleep.deadline == null || sleep.remaining > Duration.zero)) {
        unawaited(
          MediaCoordinator.instance.run(() async {
            if (!mounted || !_foreground || !identical(sleep.owner, this))
              return;
            await _controller!.seekTo(Duration.zero);
            if (!AccessPolicy.meditationAllowed(
              key,
              await SubscriptionService().isPremium(),
            ))
              return;
            await _controller!.play();
            _completionRecorded = false;
          }),
        );
      } else {
        sleep.detach(this);
        MediaCoordinator.instance.release(this);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state != AppLifecycleState.resumed) {
      unawaited(
        MediaCoordinator.instance.run(() async {
          await _pauseDirect();
          MediaCoordinator.instance.release(this);
        }),
      );
    }
  }

  Future<void> _togglePlay() async {
    if (!_exists || _initializing) return;
    unawaited(MeditationCompletionService.instance.retry());
    if (!_expanded) {
      setState(() {
        _expanded = true;
        _initializing = true;
      });
      final controller = VideoPlayerController.asset(widget.assetPath);
      try {
        await controller.initialize();
        await controller.setLooping(false);
        if (!mounted) {
          await controller.dispose();
          return;
        }
        _controller = controller;
        _sessionCompleted = false;
        await MeditationCompletionService.instance.begin(
          widget.assetPath.split('/').last.split('.').first,
        );
        _completionRecorded = false;
        controller.addListener(_onProgress);
        await _play(controller);
        if (!mounted) return;
        setState(() {
          _controller = controller;
          _initializing = false;
        });
      } catch (_) {
        MediaCoordinator.instance.release(this);
        _controller = null;
        controller.dispose();
        if (!mounted) return;
        setState(() {
          _initializing = false;
          _expanded = false;
          _exists = false; // 로드 실패 시 텍스트 가이드만 남기고 조용히 숨김
        });
      }
    } else {
      await MediaCoordinator.instance.run(() async {
        await _pauseDirect();
        MediaCoordinator.instance.release(this);
      });
      _controller?.dispose();
      if (!mounted) return;
      setState(() {
        _controller = null;
        _expanded = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MeditationSleepService.instance.detach(this);
    MediaCoordinator.instance.release(this);
    _controller?.removeListener(_onProgress);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_exists) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (context, value, child) => TextButton.icon(
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(value.isPlaying ? '일시정지' : '재생'),
                onPressed: () async {
                  final controller = _controller;
                  if (controller == null) return;
                  if (value.isPlaying) {
                    await MediaCoordinator.instance.run(() async {
                      await _pauseDirect();
                      MediaCoordinator.instance.release(this);
                    });
                  } else {
                    if (value.position >= value.duration) {
                      _sessionCompleted = false;
                      await MeditationCompletionService.instance.begin(
                        widget.assetPath.split('/').last.split('.').first,
                      );
                      _completionRecorded = false;
                      await controller.seekTo(Duration.zero);
                    }
                    await _play(controller);
                  }
                },
              ),
            ),
          if (_expanded)
            MeditationSleepControls(
              owner: this,
              allowRepeat: widget.assetPath.endsWith('/fireplaceRest.mp4'),
            ),
          if (_expanded)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: _controller?.value.isInitialized == true
                    ? _controller!.value.aspectRatio
                    : 16 / 9,
                child: _controller?.value.isInitialized == true
                    ? Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          VideoPlayer(_controller!),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: _MiniIconButton(
                              icon: Icons.close_rounded,
                              onTap: _togglePlay,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.black.withValues(alpha: 0.06),
                        alignment: Alignment.center,
                        child: _initializing
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.accent,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
              ),
            )
          else
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: widget.accent.withValues(alpha: 0.14),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      color: widget.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.assetPath.endsWith('/fireplaceRest.mp4')
                          ? '장작 이미지와 소리 재생'
                          : '영상으로 따라하기',
                      style: pathLabelFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: widget.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MiniIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
