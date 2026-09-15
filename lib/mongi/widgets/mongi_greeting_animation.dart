import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/sound_manager.dart';

/// 홈 화면 첫인상을 담당하는 몽이 인사 애니메이션 (실사 프레임 기반).
///
/// 기존에는 `cat_idle.png` 한 장 위에 코드로 도형을 덮어씌워 윙크/스윙을
/// 흉내냈지만, 그 방식은 "스티커를 붙인 듯한" 이질감이 있었다.
/// 이번에는 실제로 새로 그린 4장의 그림 프레임을 시간축에 따라 교차
/// 표시(크로스페이드)하여 훨씬 자연스러운 움직임을 만든다.
///
///  - idle          : 기본 포즈(손을 든 채 멈춰있음)
///  - cat_wave_left  : 팔이 왼쪽으로 기울며 흔드는 프레임(꼬리도 함께 반응)
///  - cat_wave_right : 팔이 오른쪽으로 더 크게 기울며 흔드는 프레임
///  - cat_wink       : 한쪽 눈을 감고 활짝 웃는 윙크 프레임
///  - heart_sticker  : 윙크 순간 두둥실 떠오르는 하트 이미지
///
/// 여기에 "야옹"(인사) / "골골"(만족) 효과음을 타이밍에 맞춰 재생해
/// 시각+청각이 함께 어우러진 인사 연출을 완성한다.
///
/// [imageAsset]이 `cat_idle.png`(인사 포즈)일 때만 이 풀 세트 연출을
/// 적용하고, 다른 표정(cat_jump/cat_cry)일 때는 은은한 숨쉬기 애니메이션만
/// 적용해 과하지 않게 만든다.
class MongiGreetingAnimation extends StatefulWidget {
  final String imageAsset;
  final double height;

  const MongiGreetingAnimation({
    super.key,
    required this.imageAsset,
    this.height = 150,
  });

  @override
  State<MongiGreetingAnimation> createState() => _MongiGreetingAnimationState();
}

/// 캐릭터 프레임 하나(에셋 경로 + 이 프레임일 때 몸통에 줄 추가 기울기/들썩임)를 표현.
class _FrameSpec {
  final String asset;
  final double tilt; // 라디안
  final double bounce; // px, 음수면 위로 살짝 들림
  const _FrameSpec(this.asset, this.tilt, this.bounce);
}

/// 인사 시퀀스 전체를 구성하는 구간 하나. [from]==[to]면 정지(hold) 구간,
/// 다르면 그 구간 동안 부드럽게 크로스페이드 전환된다.
class _Segment {
  final int startMs;
  final int endMs;
  final _FrameSpec from;
  final _FrameSpec to;
  const _Segment(this.startMs, this.endMs, this.from, this.to);
}

class _MongiGreetingAnimationState extends State<MongiGreetingAnimation>
    with TickerProviderStateMixin {
  // cat_idle.png 원본 비율(폭/높이) - 모든 프레임을 이 박스에 bottomCenter로
  // contain 정렬해 표시하므로, 프레임마다 원본 크롭 크기가 조금씩 달라도
  // 발/몸통 기준선이 흔들리지 않고 자연스럽게 이어진다.
  static const double _imageAspect = 623 / 700;

  static const String _waveLeftAsset = 'assets/mongi/images/cat_wave_left.png';
  static const String _waveRightAsset = 'assets/mongi/images/cat_wave_right.png';
  static const String _winkAsset = 'assets/mongi/images/cat_wink.png';

  static const int _cycleTotalMs = 4600;

  late final _FrameSpec _idleFrame;
  late final _FrameSpec _waveLeftFrame;
  late final _FrameSpec _waveRightFrame;
  late final _FrameSpec _winkFrame;
  late final List<_Segment> _segments;

  /// 몸 전체의 은은한 숨쉬기/들썩임을 담당하는 상시 반복 애니메이션.
  late final AnimationController _breathController;

  /// 인사 제스처 한 사이클(스윙→스윙→윙크→하트)을 재생하는 컨트롤러.
  /// repeat()가 아니라 forward()를 한 번씩 재생한 뒤, 매번 무작위 대기
  /// 시간을 두고 다시 재생해 로봇처럼 기계적으로 반복되지 않게 한다.
  late final AnimationController _sequenceController;

  Timer? _cycleTimer;
  Timer? _purrTimer;
  final Random _random = Random();
  bool _hasGreetedWithMeow = false;
  bool _hasPurredOnce = false;

  final List<_HeartParticle> _hearts = [];
  int _heartSeed = 0;

  bool get _isGreetingPose => widget.imageAsset.contains('cat_idle');

  @override
  void initState() {
    super.initState();

    _idleFrame = _FrameSpec(widget.imageAsset, 0.0, 0.0);
    _waveLeftFrame = const _FrameSpec(_waveLeftAsset, -0.085, -3.0);
    _waveRightFrame = const _FrameSpec(_waveRightAsset, 0.09, -3.0);
    _winkFrame = const _FrameSpec(_winkAsset, 0.02, -2.0);

    _segments = [
      _Segment(0, 500, _idleFrame, _idleFrame),
      _Segment(500, 850, _idleFrame, _waveLeftFrame),
      _Segment(850, 1150, _waveLeftFrame, _waveLeftFrame),
      _Segment(1150, 1450, _waveLeftFrame, _waveRightFrame),
      _Segment(1450, 1750, _waveRightFrame, _waveRightFrame),
      _Segment(1750, 2050, _waveRightFrame, _waveLeftFrame),
      _Segment(2050, 2350, _waveLeftFrame, _waveLeftFrame),
      _Segment(2350, 2700, _waveLeftFrame, _idleFrame),
      _Segment(2700, 3000, _idleFrame, _idleFrame),
      _Segment(3000, 3350, _idleFrame, _winkFrame),
      _Segment(3350, 3900, _winkFrame, _winkFrame),
      _Segment(3900, 4300, _winkFrame, _idleFrame),
      _Segment(4300, _cycleTotalMs, _idleFrame, _idleFrame),
    ];

    _breathController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isGreetingPose ? 1900 : 1400),
    )..repeat(reverse: true);

    _sequenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _cycleTotalMs),
    );

    if (_isGreetingPose) {
      _playCycle();
    }
  }

  Future<void> _playCycle() async {
    if (!mounted) return;
    // 화면에 처음 들어왔을 때 딱 한 번만 반갑게 "야옹" 하고 인사한다.
    // 이후 반복되는 사이클부터는 야옹 없이 바로 골골송으로 넘어간다.
    if (!_hasGreetedWithMeow) {
      _hasGreetedWithMeow = true;
      SoundManager.instance.playMeow();
    }

    _purrTimer?.cancel();
    _purrTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      // 윙크 + 하트가 뜨는 순간 = 기분 좋은 "골골" 소리.
      // 야옹과 마찬가지로 화면에 들어왔을 때 딱 한 번만 들려주고,
      // 이후 반복되는 사이클에서는 하트만 뜨고 소리는 내지 않는다.
      if (!_hasPurredOnce) {
        _hasPurredOnce = true;
        SoundManager.instance.playPurr();
      }
      _spawnHearts();
    });

    await _sequenceController.forward(from: 0);
    if (!mounted) return;

    final gapMs = 1300 + _random.nextInt(1500);
    _cycleTimer = Timer(Duration(milliseconds: gapMs), _playCycle);
  }

  void _spawnHearts() {
    for (var i = 0; i < 3; i++) {
      final id = _heartSeed++;
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1050 + _random.nextInt(400)),
      );
      final particle = _HeartParticle(
        id: id,
        controller: controller,
        dx: (_random.nextDouble() - 0.5) * 50,
        scale: 0.72 + _random.nextDouble() * 0.4,
        spin: (_random.nextDouble() - 0.5) * 0.6,
      );
      controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _hearts.removeWhere((h) => h.id == id));
          controller.dispose();
        }
      });
      setState(() => _hearts.add(particle));
      Future.delayed(Duration(milliseconds: i * 130), () {
        if (mounted) controller.forward();
      });
    }
  }

  /// 주어진 경과 시간(ms)에 해당하는 구간을 찾아 (from, to, blend)를 반환.
  ({_FrameSpec from, _FrameSpec to, double blend}) _resolve(double ms) {
    for (final seg in _segments) {
      if (ms >= seg.startMs && ms <= seg.endMs) {
        final span = (seg.endMs - seg.startMs).clamp(1, 1 << 30);
        final blend = ((ms - seg.startMs) / span).clamp(0.0, 1.0);
        return (from: seg.from, to: seg.to, blend: blend);
      }
    }
    return (from: _idleFrame, to: _idleFrame, blend: 0.0);
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _purrTimer?.cancel();
    _breathController.dispose();
    _sequenceController.dispose();
    for (final h in _hearts) {
      h.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    final width = height * _imageAspect;
    const sidePadding = 50.0;
    return SizedBox(
      width: width + sidePadding * 2,
      height: height + 34,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              _breathController,
              _sequenceController,
            ]),
            builder: (context, _) {
              if (!_isGreetingPose) {
                // 다른 표정일 때는 아주 은은한 숨쉬기 스케일만.
                final scale = 1.0 + _breathController.value * 0.02;
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Image.asset(
                      widget.imageAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                );
              }

              final ms = _sequenceController.value * _cycleTotalMs;
              final r = _resolve(ms);
              final tilt = _lerpD(r.from.tilt, r.to.tilt, r.blend);
              final bounceExtra = _lerpD(r.from.bounce, r.to.bounce, r.blend);

              // 상시 숨쉬기(둥실둥실) + 제스처 들썩임을 함께 더한다.
              final breathBounce = -_breathController.value * 3.2;
              final totalBounce = breathBounce + bounceExtra;

              Widget frameStack;
              if (r.from.asset == r.to.asset) {
                frameStack = Image.asset(
                  r.from.asset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                );
              } else {
                frameStack = Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: (1 - r.blend).clamp(0.0, 1.0),
                      child: Image.asset(
                        r.from.asset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                    Opacity(
                      opacity: r.blend.clamp(0.0, 1.0),
                      child: Image.asset(
                        r.to.asset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  ],
                );
              }

              return Transform.translate(
                offset: Offset(0, totalBounce),
                child: Transform.rotate(
                  angle: tilt,
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: frameStack,
                  ),
                ),
              );
            },
          ),
          ..._hearts.map((h) => _HeartWidget(heart: h, baseWidth: width)),
        ],
      ),
    );
  }

  double _lerpD(double a, double b, double t) => a + (b - a) * t;
}

class _HeartParticle {
  final int id;
  final AnimationController controller;
  final double dx;
  final double scale;
  final double spin;

  _HeartParticle({
    required this.id,
    required this.controller,
    required this.dx,
    required this.scale,
    required this.spin,
  });
}

class _HeartWidget extends StatelessWidget {
  final _HeartParticle heart;
  final double baseWidth;

  const _HeartWidget({required this.heart, required this.baseWidth});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: heart.controller,
      builder: (context, _) {
        final t = heart.controller.value;
        // 통통 튀며 나타났다가(0~0.25) 두둥실 떠오르며 사라짐(0.25~1.0).
        final popScale = t < 0.22
            ? Curves.easeOutBack.transform(t / 0.22)
            : 1.0;
        final riseY = -66 * Curves.easeOut.transform(t);
        final opacity = t < 0.65
            ? 1.0
            : (1 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
        final angle = heart.spin * Curves.easeOut.transform(t);
        return Positioned(
          top: 4 + riseY,
          right: baseWidth * 0.08 + heart.dx,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: popScale * heart.scale,
                child: Image.asset(
                  'assets/mongi/images/heart_sticker.png',
                  width: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
