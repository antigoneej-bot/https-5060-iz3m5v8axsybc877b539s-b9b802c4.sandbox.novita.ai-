import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../theme.dart';
import '../providers/app_state_provider.dart';
import 'ambient_cat_garden.dart';
import 'garden_weather_layer.dart';

/// 밝고 산뜻한 배경 위를 부드럽게 떠다니는 꽃잎 & 반짝임 파티클
class StarsBackground extends StatefulWidget {
  const StarsBackground({super.key});

  @override
  State<StarsBackground> createState() => _StarsBackgroundState();
}

class _StarsBackgroundState extends State<StarsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Petal> _petals = List.generate(18, (i) {
    final rng = Random(i * 23);
    return _Petal(
      x: rng.nextDouble(),
      startY: rng.nextDouble(),
      size: rng.nextDouble() * 6 + 5,
      speed: rng.nextDouble() * 0.4 + 0.25,
      sway: rng.nextDouble() * 0.6 + 0.2,
      phase: rng.nextDouble(),
      colorIndex: rng.nextInt(4),
    );
  });

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
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
            painter: _PetalsPainter(_petals, _controller.value),
          );
        },
      ),
    );
  }
}

class _Petal {
  final double x, startY, size, speed, sway, phase;
  final int colorIndex;
  _Petal({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.colorIndex,
  });
}

class _PetalsPainter extends CustomPainter {
  final List<_Petal> petals;
  final double t;
  _PetalsPainter(this.petals, this.t);

  static const _colors = [
    Color(0xFFF7C6D0), // 연분홍
    Color(0xFFFFE3A3), // 연노랑
    Color(0xFFC9E4C5), // 연민트
    Color(0xFFD8C7F0), // 연라벤더
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in petals) {
      // 위→아래로 천천히 낙하 + 좌우 스웨이
      final fall = ((t * p.speed) + p.phase) % 1.0;
      final y = fall * (size.height + 60) - 30;
      final swayX = sin((fall * 2 * pi * 2) + p.phase * 10) * 18 * p.sway;
      final dx = p.x * size.width + swayX;
      final opacity = (sin(fall * pi) * 0.6 + 0.15).clamp(0.0, 0.75);

      final paint = Paint()
        ..color = _colors[p.colorIndex].withValues(alpha: opacity);
      final rect = Rect.fromCenter(
        center: Offset(dx, y),
        width: p.size,
        height: p.size * 1.3,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(fall * pi * 2);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawOval(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PetalsPainter oldDelegate) => true;
}

/// 화면 구석에서 나뭇가지에 매달려 살짝살짝 흔들리는 나뭇잎 장식.
/// 배경이 비어 보이지 않도록, 아주 미세한 회전(sway)만 반복합니다.
class _SwayingLeavesLayer extends StatefulWidget {
  const _SwayingLeavesLayer();

  @override
  State<_SwayingLeavesLayer> createState() => _SwayingLeavesLayerState();
}

class _SwayingLeavesLayerState extends State<_SwayingLeavesLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
          final t = _controller.value * 2 * pi;
          return Stack(
            children: [
              Positioned(
                top: -6,
                left: -8,
                child: Transform.rotate(
                  angle: 0.55 + sin(t) * 0.06,
                  alignment: Alignment.topLeft,
                  child: const _LeafCluster(size: 46, mirrored: false),
                ),
              ),
              Positioned(
                top: -4,
                right: -10,
                child: Transform.rotate(
                  angle: -0.5 + sin(t + pi * 0.6) * 0.07,
                  alignment: Alignment.topRight,
                  child: const _LeafCluster(size: 40, mirrored: true),
                ),
              ),
              Positioned(
                bottom: 78,
                left: -6,
                child: Transform.rotate(
                  angle: -0.3 + sin(t + pi * 1.2) * 0.05,
                  alignment: Alignment.bottomLeft,
                  child: const _LeafCluster(size: 30, mirrored: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeafCluster extends StatelessWidget {
  final double size;
  final bool mirrored;
  const _LeafCluster({required this.size, required this.mirrored});

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.diagonal3Values(mirrored ? -1.0 : 1.0, 1.0, 1.0),
      alignment: Alignment.center,
      child: Opacity(
        opacity: 0.55,
        child: Text('🍃', style: TextStyle(fontSize: size)),
      ),
    );
  }
}

/// 앱 전체의 밝고 산뜻한 배경 - 따뜻한 크림빛 그라데이션 + 떠다니는 꽃잎 +
/// 살짝 흔들리는 나뭇잎 + 배경 속을 오가는 그림자 고양이들
class GardenScaffoldBackground extends StatelessWidget {
  final Widget child;
  const GardenScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 정원 날씨(최근 7일 감정 기록의 분위기)는 데이터 시각화이므로,
    // history가 갱신될 때마다(편지 저장, 앱 재실행 등) 자연스럽게 다시
    // 계산되도록 watch로 구독합니다. 별도 알림/팝업 없이 화면에 진입하는
    // 순간 배경에 조용히 반영됩니다.
    final weather = context.watch<AppStateProvider>().gardenWeather;
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.9),
          radius: 1.3,
          colors: [Color(0xFFFFF6E5), AppColors.bg0],
          stops: [0.0, 0.7],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: StarsBackground()),
          const Positioned.fill(child: _SwayingLeavesLayer()),
          Positioned.fill(child: GardenWeatherLayer(kind: weather.kind)),
          const Positioned.fill(child: AmbientCatGardenLayer()),
          child,
        ],
      ),
    );
  }
}
