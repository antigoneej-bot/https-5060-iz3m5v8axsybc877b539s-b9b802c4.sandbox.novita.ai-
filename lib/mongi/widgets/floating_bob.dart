import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 감정 몬스터 카드가 물 위에 뜬 듯 위아래로 은은하게 "둥둥" 떠다니는
/// 효과를 주는 래퍼 위젯. 사인파 기반이라 시작/끝이 뚝 끊기지 않고
/// 부드럽게 순환하며, [phase]를 다르게 주면 여러 카드가 서로 다른
/// 타이밍으로 움직여 자연스러운 물결 느낌을 낼 수 있다.
///
/// 새 이미지 없이 순수 애니메이션(Transform.translate + rotate)만으로
/// 구현한다.
class FloatingBob extends StatefulWidget {
  final Widget child;

  /// 0.0~1.0 사이 값. 카드마다 다르게 주면 둥둥 떠다니는 타이밍이
  /// 서로 어긋나서 훨씬 생동감 있게 보인다.
  final double phase;

  /// 위아래로 움직이는 최대 폭(px).
  final double amplitude;

  /// 한 사이클에 걸리는 시간.
  final Duration duration;

  const FloatingBob({
    super.key,
    required this.child,
    this.phase = 0,
    this.amplitude = 6,
    this.duration = const Duration(milliseconds: 2600),
  });

  @override
  State<FloatingBob> createState() => _FloatingBobState();
}

class _FloatingBobState extends State<FloatingBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward(from: widget.phase)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 위상을 더해 카드마다 다른 타이밍으로 움직이게 한다.
        final t = (_controller.value + widget.phase) * 2 * math.pi;
        // cos을 이용해 위쪽으로 갔다가 부드럽게 내려오는 둥둥 곡선.
        final dy = -widget.amplitude * (0.5 - 0.5 * math.cos(t));
        final tilt = math.sin(t) * 0.035; // 아주 살짝 좌우로 기우뚱
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: widget.child,
    );
  }
}
