import 'dart:math';
import 'package:flutter/material.dart';
import '../services/garden_weather_service.dart';

/// 정원 날씨(최근 7일 감정 기록의 분위기)를 파티클로 은은하게 표현하는
/// 배경 레이어.
///
/// ⚠️ 절대 문구/평가로 전달하지 않습니다 - 안개, 이슬비, 햇살, 무지개 같은
/// 대기 효과의 '분위기'로만 전달하며, 항상 아주 옅고 느리게 움직여 존재감을
/// 주장하지 않습니다(정원 배경의 다른 장식들과 같은 톤).
class GardenWeatherLayer extends StatefulWidget {
  final GardenWeatherKind kind;
  const GardenWeatherLayer({super.key, required this.kind});

  @override
  State<GardenWeatherLayer> createState() => _GardenWeatherLayerState();
}

class _GardenWeatherLayerState extends State<GardenWeatherLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final List<_FogPuff> _fogPuffs = List.generate(6, (i) {
    final rng = Random(i * 17 + 3);
    return _FogPuff(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.5,
      r: rng.nextDouble() * 70 + 90,
      speed: rng.nextDouble() * 0.3 + 0.12,
      phase: rng.nextDouble(),
    );
  });

  final List<_RainDrop> _drops = List.generate(16, (i) {
    final rng = Random(i * 29 + 7);
    return _RainDrop(
      x: rng.nextDouble(),
      phase: rng.nextDouble(),
      length: rng.nextDouble() * 10 + 14,
      speed: rng.nextDouble() * 0.3 + 0.55,
    );
  });

  final List<_SunBeam> _beams = List.generate(5, (i) {
    final rng = Random(i * 41 + 11);
    return _SunBeam(
      dx: rng.nextDouble(),
      width: rng.nextDouble() * 26 + 30,
      phase: rng.nextDouble(),
    );
  });

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _WeatherPainter(
              kind: widget.kind,
              t: _controller.value,
              fogPuffs: _fogPuffs,
              drops: _drops,
              beams: _beams,
            ),
          );
        },
      ),
    );
  }
}

class _FogPuff {
  final double x, y, r, speed, phase;
  _FogPuff({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
}

class _RainDrop {
  final double x, phase, length, speed;
  _RainDrop({
    required this.x,
    required this.phase,
    required this.length,
    required this.speed,
  });
}

class _SunBeam {
  final double dx, width, phase;
  _SunBeam({required this.dx, required this.width, required this.phase});
}

class _WeatherPainter extends CustomPainter {
  final GardenWeatherKind kind;
  final double t;
  final List<_FogPuff> fogPuffs;
  final List<_RainDrop> drops;
  final List<_SunBeam> beams;

  _WeatherPainter({
    required this.kind,
    required this.t,
    required this.fogPuffs,
    required this.drops,
    required this.beams,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case GardenWeatherKind.fog:
        _paintFog(canvas, size, density: 1.0);
        break;
      case GardenWeatherKind.drizzle:
        _paintFog(canvas, size, density: 0.4);
        _paintRain(canvas, size, intensity: 0.5);
        break;
      case GardenWeatherKind.cloudyThenClear:
        _paintFog(canvas, size, density: 0.5);
        _paintGlowPulse(canvas, size);
        break;
      case GardenWeatherKind.sunny:
        _paintSunbeams(canvas, size);
        break;
      case GardenWeatherKind.rainbowAfterRain:
        _paintRain(canvas, size, intensity: 0.18);
        _paintRainbow(canvas, size);
        break;
    }
  }

  void _paintFog(Canvas canvas, Size size, {required double density}) {
    for (final p in fogPuffs) {
      final drift = ((t * p.speed) + p.phase) % 1.0;
      final dx = (p.x * 1.4 - 0.2 + sin(drift * 2 * pi) * 0.06) * size.width;
      final dy = p.y * size.height * 0.6;
      final opacity = (0.10 + 0.05 * sin(drift * 2 * pi)) * density;
      final paint = Paint()
        ..color = const Color(
          0xFFEDEDF2,
        ).withValues(alpha: opacity.clamp(0.0, 0.35))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
      canvas.drawCircle(Offset(dx, dy), p.r, paint);
    }
  }

  void _paintRain(Canvas canvas, Size size, {required double intensity}) {
    for (final d in drops) {
      final fall = ((t * d.speed) + d.phase) % 1.0;
      final y = fall * (size.height + 40) - 20;
      final x = d.x * size.width;
      final opacity = (sin(fall * pi) * 0.35 + 0.05) * intensity;
      final paint = Paint()
        ..color = const Color(
          0xFFAFC2D6,
        ).withValues(alpha: opacity.clamp(0.0, 0.4))
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + d.length), paint);
    }
  }

  void _paintSunbeams(Canvas canvas, Size size) {
    for (final b in beams) {
      final pulse = 0.5 + 0.5 * sin((t + b.phase) * 2 * pi);
      final opacity = 0.06 + 0.05 * pulse;
      final paint = Paint()
        ..color = const Color(0xFFFFE7AE).withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      final topX = b.dx * size.width;
      final path = Path()
        ..moveTo(topX - b.width / 2, -40)
        ..lineTo(topX + b.width / 2, -40)
        ..lineTo(topX + b.width * 1.6, size.height * 0.65)
        ..lineTo(topX - b.width * 1.6, size.height * 0.65)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _paintGlowPulse(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * sin(t * 2 * pi);
    final paint = Paint()
      ..color = const Color(0xFFFFF3D6).withValues(alpha: 0.05 + 0.05 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.6,
      paint,
    );
  }

  void _paintRainbow(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFF7C6D0),
      Color(0xFFFFE3A3),
      Color(0xFFC9E4C5),
      Color(0xFFBFE0EF),
      Color(0xFFD8C7F0),
    ];
    final shimmer = 0.55 + 0.25 * sin(t * 2 * pi);
    final center = Offset(size.width * 0.5, size.height * 0.05);
    final baseRadius = size.width * 0.62;
    for (int i = 0; i < colors.length; i++) {
      final r = baseRadius - i * 14;
      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.22 * shimmer)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, pi, pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherPainter oldDelegate) => true;
}
