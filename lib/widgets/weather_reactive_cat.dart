import 'dart:math';
import 'package:flutter/material.dart';
import '../services/garden_weather_service.dart';

/// 정원 날씨(최근 감정 기록 분위기)에 따라 아기 고양이의 몸짓을 아주 미세하게
/// 바꿔주는 래퍼 위젯입니다.
///
/// ⚠️ 절대 문구로 "네 기분이 나쁘다"를 설명하지 않습니다 - 오직 움직임의
/// 크기와 속도로만 전달합니다.
/// - curledUp(안개/이슬비): 웅크린 듯 느리고 작은 숨쉬기만
/// - gentle(흐린 뒤 갬/무지개): 평온하게 살짝 흔들리는 정도
/// - playful(맑음/햇살): 통통 튀듯 발랄하게
class GardenWeatherCatMood extends StatefulWidget {
  final GardenCatActivity activity;
  final Widget child;
  const GardenWeatherCatMood({
    super.key,
    required this.activity,
    required this.child,
  });

  @override
  State<GardenWeatherCatMood> createState() => _GardenWeatherCatMoodState();
}

class _GardenWeatherCatMoodState extends State<GardenWeatherCatMood>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.activity),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant GardenWeatherCatMood oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activity != widget.activity) {
      _controller.duration = _durationFor(widget.activity);
    }
  }

  Duration _durationFor(GardenCatActivity activity) {
    switch (activity) {
      case GardenCatActivity.curledUp:
        return const Duration(seconds: 6);
      case GardenCatActivity.gentle:
        return const Duration(seconds: 4);
      case GardenCatActivity.playful:
        return const Duration(seconds: 2);
    }
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
      builder: (context, _) {
        final t = _controller.value * 2 * pi;
        switch (widget.activity) {
          case GardenCatActivity.curledUp:
            final scale = 0.95 + 0.02 * sin(t);
            return Transform.translate(
              offset: Offset(0, 2 + 1.5 * sin(t)),
              child: Transform.scale(scale: scale, child: widget.child),
            );
          case GardenCatActivity.gentle:
            final scale = 1.0 + 0.02 * sin(t);
            return Transform.scale(scale: scale, child: widget.child);
          case GardenCatActivity.playful:
            final dy = -3 * sin(t).abs();
            final angle = 0.02 * sin(t * 1.4);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(angle: angle, child: widget.child),
            );
        }
      },
    );
  }
}
