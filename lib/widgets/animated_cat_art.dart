import 'package:flutter/material.dart';
import 'dart:math';
import '../theme.dart';

/// 살아 움직이는 듯한 고양이 아트
/// - 숨쉬기(scale pulse) + 부유(float) + 살짝 씰룩임(wiggle) + 가끔 통통 튀는(hop) 동작 + 반짝임
class AnimatedCatArt extends StatefulWidget {
  final String imageAsset;
  final double size;
  const AnimatedCatArt({super.key, required this.imageAsset, this.size = 132});

  @override
  State<AnimatedCatArt> createState() => _AnimatedCatArtState();
}

class _AnimatedCatArtState extends State<AnimatedCatArt>
    with TickerProviderStateMixin {
  late AnimationController _floatController; // 기본 부유 + 숨쉬기
  late AnimationController _sparkleController; // 반짝임
  late AnimationController _hopController; // 가끔 통통 튀는 동작
  late AnimationController _earController; // 귀/꼬리 씰룩임 느낌의 미세 흔들림

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
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
    _floatController.dispose();
    _sparkleController.dispose();
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
              // 부유 (위아래 둥실둥실)
              final floatDy = -5 * sin(t * 2 * pi) - 2 * sin(t * 2 * pi + 1.4);
              // 가끔 통통 튀는 동작 (hop)
              final hopT = _hopController.value;
              final hopDy = -14 * sin(hopT * pi);
              final hopScaleY = 1.0 - 0.06 * sin(hopT * pi);
              final hopScaleX = 1.0 + 0.05 * sin(hopT * pi);
              // 좌우로 살짝 갸웃거리는 느낌
              final angle =
                  0.03 * sin(t * 2 * pi * 0.7) +
                  0.02 * sin(_earController.value * 2 * pi);
              // 숨쉬기 스케일 펄스
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
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.asset(widget.imageAsset, fit: BoxFit.cover),
              ),
            ),
          ),
          // 그림자 (통통 뛸 때 바닥에서 눌리는 느낌)
          AnimatedBuilder(
            animation: _hopController,
            builder: (context, child) {
              final hopT = _hopController.value;
              final shrink = sin(hopT * pi);
              return Positioned(
                bottom: -2,
                left: widget.size * 0.18,
                right: widget.size * 0.18,
                child: Opacity(
                  opacity: (0.22 - 0.13 * shrink).clamp(0.05, 0.35),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            },
          ),
          // sparkles
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (context, child) {
              final t1 = _sparkleController.value;
              final t2 = (_sparkleController.value + 0.5) % 1.0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -6 - 4 * sin(t1 * 2 * pi),
                    right: -4,
                    child: Opacity(
                      opacity: (0.3 + 0.5 * sin(t1 * 2 * pi).abs()).clamp(
                        0.0,
                        1.0,
                      ),
                      child: _sparkleDot(),
                    ),
                  ),
                  Positioned(
                    bottom: -4 - 4 * sin(t2 * 2 * pi),
                    left: -6,
                    child: Opacity(
                      opacity: (0.3 + 0.5 * sin(t2 * 2 * pi).abs()).clamp(
                        0.0,
                        1.0,
                      ),
                      child: _sparkleDot(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sparkleDot() {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: AppColors.goldSoft,
        shape: BoxShape.circle,
      ),
    );
  }
}
