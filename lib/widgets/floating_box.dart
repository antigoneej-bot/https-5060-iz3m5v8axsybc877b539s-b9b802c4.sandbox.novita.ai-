import 'dart:math';
import 'package:flutter/material.dart';

/// 정적인 카드가 다른 정원 UI(블롭/카드)처럼 은은하게 "둥둥 떠다니는" 느낌을
/// 갖도록 감싸주는 래퍼. [GlassBlob]/[GardenPathCard]에서 쓰는 것과 같은
/// 떠다님 리듬(사인파 기반 이동+회전)을 재사용하되, 카드 자체의 배경/테두리는
/// 건드리지 않아 기존 Container 디자인 위에 그대로 씌울 수 있습니다.
class FloatingBox extends StatefulWidget {
  final Widget child;

  /// 카드마다 다른 리듬을 주기 위한 값(선택). 지정하지 않으면 위젯 인스턴스
  /// 해시값을 사용합니다.
  final int? floatSeed;

  const FloatingBox({super.key, required this.child, this.floatSeed});

  @override
  State<FloatingBox> createState() => _FloatingBoxState();
}

class _FloatingBoxState extends State<FloatingBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    final seed = widget.floatSeed ?? identityHashCode(this);
    final rng = Random(seed);
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4200 + rng.nextInt(2600)),
    )..repeat(reverse: true, min: rng.nextDouble(), max: 1);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final t = _floatController.value;
        final dy = sin(t * pi) * 3.2;
        final angle = sin(t * pi) * 0.004;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: angle, child: child),
        );
      },
      child: widget.child,
    );
  }
}
