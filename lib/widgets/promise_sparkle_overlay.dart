import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

/// "오늘의 약속"을 모두 지키고 완료 버튼을 눌렀을 때 보여주는 전체 화면
/// 축하 효과. 고양이가 골골송을 부르는 듬 화면 중앙에 메시지가 뜨고,
/// 주변에 반짝이는 별들이 무작위로 흩날립니다.
class PromiseSparkleOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  const PromiseSparkleOverlay({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<PromiseSparkleOverlay> createState() => _PromiseSparkleOverlayState();
}

class _PromiseSparkleOverlayState extends State<PromiseSparkleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Sparkle> _sparkles = List.generate(
    16,
    (i) => _Sparkle.random(Random(i * 37 + 11)),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: widget.onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.28),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ..._sparkles.map(
                (s) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final t = (_controller.value - s.delay).clamp(0.0, 1.0);
                    final fadeOut = 1.0 - Curves.easeIn.transform(t);
                    final dy = -s.travel * Curves.easeOut.transform(t);
                    return Positioned(
                      left: s.left,
                      top: s.top + dy,
                      child: Opacity(
                        opacity: t <= 0 ? 0 : fadeOut.clamp(0.0, 1.0),
                        child: Text(
                          s.emoji,
                          style: TextStyle(fontSize: s.size),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blobButter.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.blobButterAccent.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blobButterAccent.withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 26,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😽', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: pathLabelFont(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkle {
  final double left;
  final double top;
  final double travel;
  final double size;
  final double delay;
  final String emoji;

  _Sparkle({
    required this.left,
    required this.top,
    required this.travel,
    required this.size,
    required this.delay,
    required this.emoji,
  });

  factory _Sparkle.random(Random rng) {
    const emojis = ['✨', '⭐', '💫', '🌟'];
    return _Sparkle(
      left: 20 + rng.nextDouble() * 280,
      top: 120 + rng.nextDouble() * 360,
      travel: 40 + rng.nextDouble() * 80,
      size: 14 + rng.nextDouble() * 14,
      delay: rng.nextDouble() * 0.5,
      emoji: emojis[rng.nextInt(emojis.length)],
    );
  }
}
