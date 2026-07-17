import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 청소년(1단계) 고양이 전용 애니메이션 위젯.
///
/// assets/growth/teen_frames/teen_01.png ~ teen_15.png 15장의 각기 다른
/// 포즈(손흔들기/웃기/꼬리흔들기/눕기 등) 스티커 프레임을 순서대로 부드럽게
/// 크로스페이드하며 돌려서, 마치 살아 움직이는 것처럼 보여줍니다.
/// 아기 고양이([MochiCat])와 청년/성체([AnimatedCatArt])와 마찬가지로
/// 부유(float)+숨쉬기(breath)+가끔 통통 튀는(hop) 미세 움직임도 함께 줘서
/// 톤을 통일했습니다.
class AnimatedTeenCat extends StatefulWidget {
  final double size;
  const AnimatedTeenCat({super.key, this.size = 132});

  @override
  State<AnimatedTeenCat> createState() => _AnimatedTeenCatState();
}

class _AnimatedTeenCatState extends State<AnimatedTeenCat>
    with TickerProviderStateMixin {
  static const List<String> _frames = [
    'assets/growth/teen_frames/teen_01.png',
    'assets/growth/teen_frames/teen_02.png',
    'assets/growth/teen_frames/teen_03.png',
    'assets/growth/teen_frames/teen_04.png',
    'assets/growth/teen_frames/teen_05.png',
    'assets/growth/teen_frames/teen_06.png',
    'assets/growth/teen_frames/teen_07.png',
    'assets/growth/teen_frames/teen_08.png',
    'assets/growth/teen_frames/teen_09.png',
    'assets/growth/teen_frames/teen_10.png',
    'assets/growth/teen_frames/teen_11.png',
    'assets/growth/teen_frames/teen_12.png',
    'assets/growth/teen_frames/teen_13.png',
    'assets/growth/teen_frames/teen_14.png',
    'assets/growth/teen_frames/teen_15.png',
  ];

  Timer? _frameTimer;
  int _frameIndex = 0;

  late final AnimationController _floatController; // 기본 부유 + 숨쉬기
  late final AnimationController _hopController; // 가끔 통통 튀는 동작
  late final AnimationController _earController; // 미세한 씰룩임

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _frameIndex = _rng.nextInt(_frames.length);

    // 1.6초마다 다음 포즈로 순환 (AnimatedSwitcher가 크로스페이드로 자연스럽게 연결)
    _frameTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (!mounted) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % _frames.length;
      });
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _earController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scheduleNextHop();
  }

  void _scheduleNextHop() {
    final delay = Duration(milliseconds: 2600 + _rng.nextInt(3200));
    Future.delayed(delay, () {
      if (!mounted) return;
      _hopController.forward(from: 0).then((_) {
        if (mounted) _hopController.reverse();
      });
      _scheduleNextHop();
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _floatController.dispose();
    _hopController.dispose();
    _earController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size + 10,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatController,
              _hopController,
              _earController,
            ]),
            builder: (context, child) {
              final t = _floatController.value;
              final floatDy =
                  -5 * sin(t * 2 * pi) - 2 * sin(t * 2 * pi + 1.4);
              final hopT = _hopController.value;
              final hopDy = -14 * sin(hopT * pi);
              final hopScaleY = 1.0 - 0.06 * sin(hopT * pi);
              final hopScaleX = 1.0 + 0.05 * sin(hopT * pi);
              final angle =
                  0.03 * sin(t * 2 * pi * 0.7) +
                  0.02 * sin(_earController.value * 2 * pi);
              final breathScale = 1.0 + 0.018 * sin(t * 2 * pi * 1.3);

              return Transform.translate(
                offset: Offset(0, floatDy + hopDy),
                child: Transform.rotate(
                  angle: angle,
                  child: Transform.scale(
                    scaleX: breathScale * hopScaleX,
                    scaleY: breathScale * hopScaleY,
                    child: child,
                  ),
                ),
              );
            },
            // 배경/테두리/그림자 박스 없이, 투명 배경 스티커 이미지 그대로
            // 아기 고양이(모찌)와 똑같은 방식으로 자연스럽게 떠 있도록 합니다.
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Image.asset(
                  _frames[_frameIndex],
                  key: ValueKey(_frameIndex),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
          // 그림자 (통통 뛸 때 바닥에서 눌리는 느낌, 발밑에 은은하게)
          AnimatedBuilder(
            animation: _hopController,
            builder: (context, child) {
              final hopT = _hopController.value;
              final shrink = sin(hopT * pi);
              return Positioned(
                bottom: 2,
                left: widget.size * 0.26,
                right: widget.size * 0.26,
                child: Opacity(
                  opacity: (0.18 - 0.1 * shrink).clamp(0.04, 0.28),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
