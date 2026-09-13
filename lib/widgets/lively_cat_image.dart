import 'package:flutter/material.dart';
import 'dart:math';

/// 그리드나 리스트에 촘촘히 나열되는 고양이 이미지에 쓰는
/// 가벼운 '살아있는' 움직임 애니메이션 위젯.
/// AnimatedCatArt보다 훨씬 저비용이라 42마리를 한 번에 그려도 부드럽습니다.
/// - 둥실둥실 부유 + 살짝 좌우로 갸웃거리는 정도의 미세한 움직임만 적용합니다.
class LivelyCatImage extends StatefulWidget {
  final String imageAsset;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const LivelyCatImage({
    super.key,
    required this.imageAsset,
    required this.width,
    required this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  State<LivelyCatImage> createState() => _LivelyCatImageState();
}

class _LivelyCatImageState extends State<LivelyCatImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phase; // 고양이마다 다른 위상을 줘서 서로 다르게 움직이도록
  late final double _speedFactor;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.imageAsset.hashCode);
    _phase = rng.nextDouble() * 2 * pi;
    _speedFactor = 0.85 + rng.nextDouble() * 0.5; // 0.85 ~ 1.35
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2600 / _speedFactor).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    // RepaintBoundary로 이 고양이 하나의 애니메이션 리페인트가 그리드의
    // 다른 고양이들까지 함께 다시 그리지 않도록 격리합니다.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value * 2 * pi + _phase;
          final floatDy = -3.2 * sin(t);
          final tilt = 0.045 * sin(t * 0.8);
          final scale = 1.0 + 0.015 * sin(t * 1.4);
          return Transform.translate(
            offset: Offset(0, floatDy),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: radius,
          child: Image.asset(
            widget.imageAsset,
            width: widget.width.isFinite ? widget.width : null,
            height: widget.height.isFinite ? widget.height : null,
            fit: widget.fit,
            // 원본(1024x1024)을 실제 표시 크기에 맞춰 디코딩해 메모리 사용량을
            // 크게 낮춥니다(디바이스 배율 감안해 2배 정도 여유를 둡니다).
            // width/height가 infinity면 round()가 예외를 내서 공유 카드 전체가
            // 빈 칸으로 보이므로, 유한할 때만 cache 크기를 지정합니다.
            cacheWidth: widget.width.isFinite
                ? (widget.width * 2).round()
                : null,
            cacheHeight: widget.height.isFinite
                ? (widget.height * 2).round()
                : null,
          ),
        ),
      ),
    );
  }
}
